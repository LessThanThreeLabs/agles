import random
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
from util.permissions import AdminApi


class SystemSettingsReadHandler(ModelServerRpcHandler):

	def __init__(self):
		super(SystemSettingsReadHandler, self).__init__("system_settings", "read")

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
	def get_website_domain_name(self, user_id):
		return WebServerSettings.domain_name

	@AdminApi
	def get_aws_keys(self, user_id):
		aws_access_key_id = AwsSettings.aws_access_key_id
		aws_secret_access_key = AwsSettings.aws_secret_access_key
		return {"access_key": aws_access_key_id, "secret_key": aws_secret_access_key}

	@AdminApi
	def get_s3_bucket_name(self, user_id):
		return AwsSettings.s3_bucket_name

	@AdminApi
	def get_allowed_instance_sizes(self, user_id):
		largest_instance_type = AwsSettings.largest_instance_type
		instance_types = ['m1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge',
			'm3.xlarge', 'm3.2xlarge', 'c1.medium', 'c1.xlarge', 'hi1.4xlarge', 'hs1.8xlarge']
		if largest_instance_type in instance_types:
			return instance_types[:instance_types.index(largest_instance_type) + 1]
		else:
			return instance_types

	@AdminApi
	def get_instance_settings(self, user_id):
		instance_size = AwsSettings.instance_type
		num_waiting = VerificationServerSettings.static_pool_size
		max_running = VerificationServerSettings.max_virtual_machine_count
		return {"instance_size": instance_size, "num_waiting": num_waiting, "max_running": max_running}

	@AdminApi
	def get_ssh_public_key(self, user_id):
		return StoreSettings.ssh_public_key

	@AdminApi
	def get_max_repository_count(self, user_id):
		return StoreSettings.max_repository_count
