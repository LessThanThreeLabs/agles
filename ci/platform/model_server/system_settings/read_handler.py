import random
import requests
import simplejson
import string

from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from settings.aws import AwsSettings
from settings.verification_server import VerificationServerSettings
from settings.web_server import WebServerSettings
from settings.deployment import DeploymentSettings
from settings.store import StoreSettings
from model_server.system_settings import system_settings_cipher
from util.crypto_yaml import CryptoYaml
from util.permissions import AdminApi, is_admin
from upgrade import upgrade_check_url
from virtual_machine import ec2


class SystemSettingsReadHandler(ModelServerRpcHandler):

	def __init__(self, channel=None):
		super(SystemSettingsReadHandler, self).__init__("system_settings", "read", channel)

	def is_deployment_initialized(self):
		result = self.get_setting("deployment", "initialized")
		return result if result else False

	def get_setting(self, resource, key):
		system_setting = database.schema.system_setting
		query = system_setting.select().where(
			and_(
				system_setting.c.resource == resource,
				system_setting.c.key == key
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			return CryptoYaml(system_settings_cipher).load(row[system_setting.c.value]) if row else None

	@AdminApi
	def get_admin_api_key(self, user_id):
		admin_api_key = DeploymentSettings.admin_api_key
		if not admin_api_key:
			admin_api_key = ''.join(random.choice(string.ascii_lowercase + string.digits) for x in range(32))
			DeploymentSettings.admin_api_key = admin_api_key
		return admin_api_key

	@AdminApi
	def is_admin_api_enabled(self, user_id):
		return DeploymentSettings.admin_api_active

	@AdminApi
	def get_website_domain_name(self, user_id):
		return WebServerSettings.domain_name

	@AdminApi
	def get_cloud_provider(self, user_id):
		return VerificationServerSettings.cloud_provider

	@AdminApi
	def get_aws_keys(self, user_id):
		return {
			'access_key': AwsSettings.aws_access_key_id,
			'secret_key': AwsSettings.aws_secret_access_key
		}

	@AdminApi
	def get_s3_bucket_name(self, user_id):
		return AwsSettings.s3_bucket_name

	@AdminApi
	def get_allowed_instance_sizes(self, user_id):
		return ec2.InstanceTypes.get_allowed_instance_types()

	@AdminApi
	def get_instance_settings(self, user_id):
		return {
			'instance_size': AwsSettings.instance_type,
			'num_waiting': VerificationServerSettings.static_pool_size,
			'max_running': VerificationServerSettings.max_virtual_machine_count
		}

	@AdminApi
	def get_ssh_public_key(self, user_id):
		return StoreSettings.ssh_public_key

	@AdminApi
	def get_max_repository_count(self, user_id):
		return StoreSettings.max_repository_count

	@AdminApi
	def get_license_key(self, user_id):
		return DeploymentSettings.license_key

	def get_license_information(self, user_id):
		return {
			'active': DeploymentSettings.active,
			'license_type': DeploymentSettings.license_type,
			'license_trial_expiration_time': DeploymentSettings.license_trial_expiration_time,
			'license_unpaid_expiration_time': DeploymentSettings.license_unpaid_expiration_time
		}

	@AdminApi
	def get_upgrade_status(self, user_id):
		request_params = {'licenseKey': DeploymentSettings.license_key, 'serverId': DeploymentSettings.server_id, 'currentVersion': DeploymentSettings.version}
		try:
			response = requests.get(upgrade_check_url, params=request_params, verify=False)
			if response.ok:
				upgrade_available = simplejson.loads(response.text).get('upgradeAvailable', False)
				upgrade_version = simplejson.loads(response.text).get('upgradeVersion')
			else:
				upgrade_available = False
				upgrade_version = None
		except:
			upgrade_available = False
			upgrade_version = None

		return {'last_upgrade_status': DeploymentSettings.upgrade_status, 'upgrade_available': upgrade_available, 'upgrade_version': upgrade_version}

	def can_hear_system_settings_events(self, user_id, id_to_listen_to):
		return is_admin(user_id)
