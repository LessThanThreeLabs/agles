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
	def set_allowed_connection_types(self, user_id, allowed_connection_types):
		valid_connection_types = ['default', 'google']
		assert isinstance(allowed_connection_types, list)
		assert set(allowed_connection_types).issubset(valid_connection_types)
		self.update_setting("authentication", "allowed_connection_types", allowed_connection_types)
		self.publish_event("system_settings", None, "allowed connection types updated",
			allowed_connection_types=allowed_connection_types)

	@AdminApi
	def set_allowed_email_domains(self, user_id, allowed_email_domains):
		assert isinstance(allowed_email_domains, list)
		for domain in allowed_email_domains:
			assert isinstance(domain, (str, unicode))
		self.update_setting("authentication", "allowed_email_domains", allowed_email_domains)
		self.publish_event("system_settings", None, "allowed email domains updated",
			allowed_email_domains=allowed_email_domains)

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
	def set_aws_instance_settings(self, user_id, security_group_id, subnet_id):
		assert VerificationServerSettings.cloud_provider == 'aws'
		self.update_setting("aws", "security_group", security_group_id)
		self.update_setting("aws", "subnet_id", subnet_id)
		self.publish_event("system_settings", None, "aws instance settings updated",
			security_group_id=security_group_id,
			subnet_id=subnet_id)

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
	def set_verifier_pool_parameters(self, user_id, pool_id, min_ready, max_running, instance_type, ami_id, vm_username, root_drive_size, user_data):
		assert min_ready <= max_running
		assert isinstance(root_drive_size, int)

		if pool_id == 0:
			self.update_setting("verification_server", "static_pool_size", min_ready)
			self.update_setting("verification_server", "max_virtual_machine_count", max_running)
			self.update_setting("aws", "instance_type", instance_type)
			self.update_setting("aws", "vm_image_id", ami_id)
			self.update_setting("aws", "vm_username", vm_username)
			self.update_setting("aws", "root_drive_size", root_drive_size)
			self.update_setting("aws", "user_data", user_data)
		else:
			secondary_pool = database.schema.secondary_pool
			update = secondary_pool.update().where(secondary_pool.c.id == pool_id).values(
				min_ready=min_ready,
				max_running=max_running,
				instance_type=instance_type,
				ami_id=ami_id,
				vm_username=vm_username,
				root_drive_size=root_drive_size,
				user_data=user_data,
			)

			with ConnectionFactory.get_sql_connection() as sqlconn:
				sqlconn.execute(update)

		self.publish_event("system_settings", None, "verifier pool settings updated",
			pool_id=pool_id,
			min_ready=min_ready,
			max_running=max_running,
			instance_type=instance_type,
			ami_id=ami_id,
			vm_username=vm_username,
			root_drive_size=root_drive_size,
			user_data=user_data,
		)


	@AdminApi
	def create_verifier_pool(self, user_id, name, min_ready, max_running, instance_type, ami_id, vm_username, root_drive_size, user_data):
		assert name != 'default'
		assert min_ready <= max_running
		assert isinstance(root_drive_size, int)

		secondary_pool = database.schema.secondary_pool
		ins = secondary_pool.insert().values(
			name=name,
			min_ready=min_ready,
			max_running=max_running,
			instance_type=instance_type,
			ami_id=ami_id,
			vm_username=vm_username,
			root_drive_size=root_drive_size,
			user_data=user_data,
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)

		pool_id = result.inserted_primary_key[0]

		self.publish_event("system_settings", None, "verifier pool created",
			pool_id=pool_id,
			min_ready=min_ready,
			max_running=max_running,
			instance_type=instance_type,
			ami_id=ami_id,
			vm_username=vm_username,
			root_drive_size=root_drive_size,
			user_data=user_data,
		)

		return pool_id

	@AdminApi
	def delete_verifier_pool(self, user_id, pool_id):
		secondary_pool = database.schema.secondary_pool
		update = secondary_pool.update().where(secondary_pool.c.id == pool_id).values(deleted=pool_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(update)

		if result.rowcount == 0:
			raise Exception("Verifier pool %s not found" % pool_id)

		self.publish_event("system_settings", None, "verifier pool deleted", pool_id=pool_id)

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
	def set_github_enterprise_config(self, user_id, url, client_id, client_secret):
		self.update_setting("github_enterprise", "github_url", url)
		self.update_setting("github_enterprise", "client_id", client_id)
		self.update_setting("github_enterprise", "client_secret", client_secret)
		self.publish_event("system_settings", None, "github enterprise settings updated",
			url=url,
			client_id=client_id,
			client_secret=client_secret)

	@AdminApi
	def set_notification_config(self, user_id, hipchat_config):
		self.update_setting("hipchat", "token", hipchat_config['token'])
		self.update_setting("hipchat", "rooms", hipchat_config['rooms'])
		self.update_setting("hipchat", "type", hipchat_config['type'])
		self.publish_event("system_settings", None, "notification settings updated",
			hipchat=hipchat_config)

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
