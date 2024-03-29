import eventlet
import requests
import simplejson

import util.greenlets
import model_server

from settings.deployment import DeploymentSettings
from settings.store import StoreSettings
from settings.verification_server import VerificationServerSettings
from util.log import Logged
from virtual_machine import ec2


LICENSE_VERIFICATION_URL = 'https://license.koalitycode.com/license/check'
MAX_FAILURES = 12


class LicenseVerifier(object):
	def __init__(self, key_verifier, permissions_handler, sleep_time=3600):
		super(LicenseVerifier, self).__init__()
		self.key_verifier = key_verifier
		self.permissions_handler = permissions_handler
		self.sleep_time = sleep_time

	def run(self):
		poller_greenlet = eventlet.spawn(self.poll)
		return poller_greenlet

	def poll(self):
		while True:
			self._poll_and_wait()

	def _poll_and_wait(self):
		self.handle_once()
		eventlet.sleep(self.sleep_time)

	def handle_once(self):
		try:
			license_key = DeploymentSettings.license_key
			server_id = DeploymentSettings.server_id

			with model_server.rpc_connect('users', 'read') as users_read_rpc:
				user_count = users_read_rpc.get_user_count()

			response = self.key_verifier.verify_valid(license_key, server_id, user_count)

			if response and response['isValid']:
				self.license_check_passed(response)
			else:
				self.license_check_failed(reason=response.get('reason'))
		except eventlet.greenlet.GreenletExit:
			raise
		except:
			self.license_check_failed(reason='Failed to reach license server')

	def reset_license_check_failures(self):
		DeploymentSettings.license_validation_failures = 0
		DeploymentSettings.license_failure_reason = None
		DeploymentSettings.active = True
		if DeploymentSettings.upgrade_status == 'running':
			DeploymentSettings.upgrade_status = 'failed'

	def license_check_passed(self, response):
		DeploymentSettings.license_type = response['licenseType']
		DeploymentSettings.license_trial_expiration_time = response['trialExpiration']
		DeploymentSettings.license_unpaid_expiration_time = response['unpaidExpiration']

		self.permissions_handler.handle_permissions(response.get('permissions', {}))
		self.reset_license_check_failures()

	def license_check_failed(self, reason='Unknown license check error'):
		failures = DeploymentSettings.license_validation_failures + 1
		DeploymentSettings.license_validation_failures = failures
		if failures > MAX_FAILURES:
			DeploymentSettings.active = False
			DeploymentSettings.license_failure_reason = reason


class LicenseKeyVerifier(object):
	def verify_valid(self, license_key, server_id, user_count):
		raise NotImplementedError("Subclasses should override this!")


@Logged()
class HttpLicenseKeyVerifier(LicenseKeyVerifier):
	def __init__(self, verification_url=LICENSE_VERIFICATION_URL):
		self.verification_url = verification_url

	def verify_valid(self, license_key, server_id, user_count=0):
		verification_data = {'licenseKey': license_key, 'serverId': server_id}
		system_metadata = {'userCount': user_count}
		request_params = dict(verification_data.items() + system_metadata.items())

		response = requests.get(self.verification_url, params=request_params, verify=False)
		if not response.ok:
			self.logger.critical("License check failed: url: %s, params: %s, response: %s" %
				(self.verification_url, request_params, {'text': response.text, 'code': response.status_code}))
			return {'isValid': False, 'reason': response.text}
		return simplejson.loads(response.text)


@Logged()
class LicensePermissionsHandler(object):
	def __init__(self):
		def handle_largest_instance_type(value):
			largest_instance_type = str(value) if value is not None else None
			ec2.InstanceTypes.set_largest_instance_type(largest_instance_type)

		def handle_parallelization_cap(value):
			VerificationServerSettings.parallelization_cap = int(value) if value is not None else None

		def handle_max_repository_count(value):
			if value is not None:
				max_repository_count = int(value)
				StoreSettings.max_repository_count = max_repository_count
				with model_server.rpc_connect('repos', 'delete') as repos_delete_rpc:
					repos_delete_rpc.truncate_repositories(max_repository_count)
			else:
				StoreSettings.max_repository_count = None

		def handle_admin_api_allowed(value):
			if value is None:
				DeploymentSettings.admin_api_active = True
			else:
				DeploymentSettings.admin_api_active = bool(value)

		self._permissions_handlers = {
			'largestInstanceType': handle_largest_instance_type,
			'parallelizationCap': handle_parallelization_cap,
			'maxRepositoryCount': handle_max_repository_count,
			'adminApiAllowed': handle_admin_api_allowed
		}

	def handle_permissions(self, permissions):
		for key, handler in self._permissions_handlers.items():
			try:
				handler(permissions.get(key))
			except:
				self.logger.error('Error while handling license permissions: %s' % permissions, exc_info=True)
