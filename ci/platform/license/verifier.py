import eventlet
import requests
import simplejson

import util.greenlets
import model_server

from settings.deployment import DeploymentSettings
from util.log import Logged


# TODO: this is very much a temporary url
LICENSE_VERIFICATION_URL = 'http://staging.koalitycode.com:9001/license/check'
MAX_FAILURES = 12


class LicenseVerifier(object):
	def __init__(self, key_verifier, sleep_time=3600):
		super(LicenseVerifier, self).__init__()
		self.key_verifier = key_verifier
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
			key = DeploymentSettings.license_key
			server_id = DeploymentSettings.server_id
			response = self.key_verifier.verify_valid(key, server_id)

			if response and response['is_valid']:
				self.reset_license_check_failures()
			else:
				self.license_check_failed()
		except eventlet.greenlet.GreenletExit:
			raise
		except:
			self.license_check_failed()

	def reset_license_check_failures(self):
		DeploymentSettings.license_validation_failures = 0
		DeploymentSettings.active = True

	def license_check_failed(self):
		failures = DeploymentSettings.license_validation_failures + 1
		DeploymentSettings.license_validation_failures = failures

		if failures > MAX_FAILURES:
			DeploymentSettings.active = False


class LicenseKeyVerifier(object):
	def verify_valid(self, key, server_id):
		raise NotImplementedError("Subclasses should override this!")


@Logged()
class HttpLicenseKeyVerifier(LicenseKeyVerifier):
	def __init__(self, verification_url=LICENSE_VERIFICATION_URL):
		self.verification_url = verification_url

	def verify_valid(self, key, server_id):
		with model_server.rpc_connect('users', 'read') as users_read_rpc:
			user_count = users_read_rpc.get_user_count()

		verification_data = {'license_key': key, 'server_id': server_id}
		system_metadata = {'user_count': user_count}
		request_data = dict(verification_data.items() + system_metadata.items())

		response = requests.post(self.verification_url, data=request_data)
		if not response.ok:
			self.logger.critical("License check failed: url: %s, data: %s, response: %s" %
				(self.verification_url, request_data, {'text': response.text, 'code': response.status_code}))
			return False
		return simplejson.loads(response.text)
