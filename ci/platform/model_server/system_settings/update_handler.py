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
from settings.deployment import DeploymentSettings
from model_server.system_settings import system_settings_cipher
from util.crypto_yaml import CryptoYaml
from util.permissions import AdminApi
from virtual_machine.ec2 import Ec2Client


class SystemSettingsUpdateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(SystemSettingsUpdateHandler, self).__init__("system_settings", "update")

	@AdminApi
	def initialize_deployment(self, user_id, test_mode=False):
		server_id = str(uuid.uuid1())

		self.update_setting("mail", "test_mode", test_mode)
		self.update_setting("deployment", "initialized", True)
		self.update_setting("deployment", "server_id", server_id)
		self.regenerate_ssh_key()
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

	@AdminApi
	def set_cloud_provider(self, user_id, cloud_provider):
		self.update_setting("verification_server", "cloud_provider", cloud_provider)

	@AdminApi
	def set_aws_keys(self, user_id, access_key, secret_key, validate=True):
		if validate and not Ec2Client.validate_credentials(access_key, secret_key):
			raise InvalidConfigurationException(access_key, secret_key)
		self.update_setting("aws", "aws_access_key_id", access_key)
		self.update_setting("aws", "aws_secret_access_key", secret_key)

	@AdminApi
	def set_s3_bucket_name(self, user_id, bucket_name):
		self.update_setting("aws", "s3_bucket_name", bucket_name)

	@AdminApi
	def set_instance_settings(self, user_id, instance_size, min_unallocated, max_verifiers):
		self.update_setting("aws", "instance_type", instance_size)
		self.update_setting("verification_server", "static_pool_size", min_unallocated)
		self.update_setting("verification_server", "max_virtual_machine_count", max_verifiers)
		self.publish_event("system_settings", None, "instance settings updated",
			instance_size=instance_size,
			min_unallocated=min_unallocated,
			max_verifiers=max_verifiers)

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
