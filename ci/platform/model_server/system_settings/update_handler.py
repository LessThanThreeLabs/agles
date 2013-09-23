import os
import random
import string
import sys
import uuid

from subprocess import Popen

from Crypto.PublicKey import RSA
from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from license.verifier import HttpLicenseKeyVerifier, LicenseVerifier, LicensePermissionsHandler
from model_server.rpc_handler import ModelServerRpcHandler
from settings.aws import AwsSettings
from settings.deployment import DeploymentSettings
from settings.verification_server import VerificationServerSettings
from model_server.system_settings import system_settings_cipher
from util.crypto_yaml import CryptoYaml
from util.permissions import AdminApi
from virtual_machine.ec2 import Ec2Client
from virtual_machine.hpcloud import HpCloudClient


class SystemSettingsUpdateHandler(ModelServerRpcHandler):
	def __init__(self, channel=None):
		super(SystemSettingsUpdateHandler, self).__init__("system_settings", "update", channel)

	@AdminApi
	def initialize_deployment(self, user_id, test_mode=False):
		server_id = str(uuid.uuid1())
		self.update_setting("mail", "test_mode", test_mode)
		self.update_setting("deployment", "initialized", True)
		self.update_setting("deployment", "server_id", server_id)
		self.regenerate_ssh_key(user_id)
		if not test_mode:
			LicenseVerifier(HttpLicenseKeyVerifier(), LicensePermissionsHandler()).handle_once()

	def update_setting(self, resource, key, value):
		system_setting = database.schema.system_setting
		query = system_setting.select().where(
			and_(
				system_setting.c.resource == resource,
				system_setting.c.key == key
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			update_command = self._get_update_command(resource, key, value) if row else self._get_insert_command(resource, key, value)
			sqlconn.execute(update_command)
		self.publish_event_to_admins("system_settings", "system setting updated", resource=resource, key=key, value=value)

	def _get_update_command(self, resource, key, value):
		system_setting = database.schema.system_setting
		return system_setting.update().where(
			and_(
				system_setting.c.resource == resource,
				system_setting.c.key == key
			)
		).values(
			value=CryptoYaml(system_settings_cipher).dump(value)
		)

	def _get_insert_command(self, resource, key, value):
		system_setting = database.schema.system_setting
		return system_setting.insert().values(
			resource=resource,
			key=key,
			value=CryptoYaml(system_settings_cipher).dump(value)
		)

	def reset_setting(self, resource, key):
		system_setting = database.schema.system_setting
		delete_command = system_setting.delete().where(
			and_(
				system_setting.c.resource == resource,
				system_setting.c.key == key
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(delete_command)

	@AdminApi
	def set_website_domain_name(self, user_id, domain_name):
		self.update_setting("web_server", "domain_name", domain_name)
		self.publish_event("system_settings", None, "domain name updated",
			domain_name=domain_name)

	@AdminApi
	def set_cloud_provider(self, user_id, cloud_provider):
		self.update_setting("verification_server", "cloud_provider", cloud_provider)

	@AdminApi
	def set_aws_keys(self, user_id, access_key, secret_key, validate=True):
		assert VerificationServerSettings.cloud_provider == 'aws'
		if validate and not Ec2Client.validate_credentials(access_key, secret_key):
			raise InvalidConfigurationException(access_key, secret_key)
		self.update_setting("aws", "aws_access_key_id", access_key)
		self.update_setting("aws", "aws_secret_access_key", secret_key)
		self.publish_event("system_settings", None, "aws keys updated",
			access_key=access_key,
			secret_key=secret_key)

	@AdminApi
	def set_aws_instance_settings(self, user_id, instance_size, root_drive_size, security_group_name, user_data):
		assert VerificationServerSettings.cloud_provider == 'aws'
		assert isinstance(root_drive_size, int)
		assert root_drive_size >= AwsSettings._default_root_drive_size
		self.update_setting("aws", "instance_type", instance_size)
		self.update_setting("aws", "root_drive_size", root_drive_size)
		self.update_setting("aws", "security_group", security_group_name)
		self.update_setting("aws", "user_data", user_data)
		self.publish_event("system_settings", None, "aws instance settings updated",
			instance_size=instance_size,
			root_drive_size=root_drive_size,
			security_group_name=security_group_name)

	@AdminApi
	def set_s3_bucket_name(self, user_id, bucket_name):
		assert VerificationServerSettings.cloud_provider == 'aws'
		self.update_setting("aws", "s3_bucket_name", bucket_name)
		self.publish_event("system_settings", None, "s3 bucket name updated",
			bucket_name=bucket_name)

	@AdminApi
	def set_hpcloud_keys(self, user_id, access_key, secret_key, tenant_name, region, validate=True):
		assert VerificationServerSettings.cloud_provider == 'hpcloud'
		credentials = {
			'key': access_key,
			'secret': secret_key,
			'ex_tenant_name': tenant_name,
			'ex_force_service_region': region
		}

		if validate and not HpCloudClient.validate_credentials(credentials):
			raise InvalidConfigurationException(access_key, secret_key, tenant_name, region)
		self.update_setting("lib_cloud", "key", access_key)
		self.update_setting("lib_cloud", "secret", secret_key)
		self.update_setting("lib_cloud", "extra_credentials", {
			"ex_tenant_name": tenant_name,
			"ex_force_service_region": region
		})
		self.publish_event("system_settings", None, "hpcloud keys updated",
			access_key=access_key,
			secret_key=secret_key,
			tenant_name=tenant_name,
			region=region)

	@AdminApi
	def set_hpcloud_instance_settings(self, user_id, instance_size, security_group_name):
		assert VerificationServerSettings.cloud_provider == 'hpcloud'
		self.update_setting("lib_cloud", "instance_type", instance_size)
		self.update_setting("lib_cloud", "security_group", security_group_name)
		self.publish_event("system_settings", None, "hpcloud instance settings updated",
			instance_size=instance_size,
			security_group_name=security_group_name)

	@AdminApi
	def set_verifier_pool_parameters(self, user_id, min_ready, max_running):
		assert min_ready <= max_running
		self.update_setting("verification_server", "static_pool_size", min_ready)
		self.update_setting("verification_server", "max_virtual_machine_count", max_running)
		self.publish_event("system_settings", None, "verifier pool settings updated",
			min_ready=min_ready,
			max_running=max_running)

	@AdminApi
	def validate_license_key(self, user_id, license_key):
		return HttpLicenseKeyVerifier().verify_valid(license_key, DeploymentSettings.server_id)

	@AdminApi
	def set_license_key(self, user_id, license_key):
		self.update_setting("deployment", "license_key", license_key)

	@AdminApi
	def regenerate_api_key(self, user_id):
		new_admin_api_key = ''.join(random.choice(string.ascii_lowercase + string.digits) for x in range(32))
		self.update_setting("deployment", "admin_api_key", new_admin_api_key)
		self.publish_event("system_settings", None, "admin api key updated",
			api_key=new_admin_api_key)
		return new_admin_api_key

	@AdminApi
	def regenerate_ssh_key(self, user_id):
		private_key = RSA.generate(2048)
		public_key = private_key.publickey()
		self.update_setting("store", "ssh_private_key", private_key.exportKey())
		self.update_setting("store", "ssh_public_key", public_key.exportKey('OpenSSH'))

	@AdminApi
	def upgrade_deployment(self, user_id):
		if DeploymentSettings.upgrade_status == 'running':
			raise UpgradeInProgressException()
		upgrade_script = os.path.join(sys.prefix, 'bin', 'koality-upgrade')

		Popen(upgrade_script)


class InvalidConfigurationException(Exception):
	pass


class UpgradeInProgressException(Exception):
	def __init__(self):
		super(UpgradeInProgressException, self).__init__('An upgrade is already in progress')
