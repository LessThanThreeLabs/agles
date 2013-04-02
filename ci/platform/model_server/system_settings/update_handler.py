import yaml

from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from settings.aws import AwsSettings
from settings.verification_server import VerificationServerSettings
from settings.web_server import WebServerSettings
from util.permissions import AdminApi


class SystemSettingsUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(SystemSettingsUpdateHandler, self).__init__("system_settings", "update")

	def initialize_deployment(self):
		self.update_setting("mail", "test_mode", False)
		self.update_setting("deployment", "initialized", True)

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
		self.publish_event("system_settings", None, "system setting updated", resource=resource, key=key, value=value)

	def _get_update_command(self, resource, key, value):
		system_setting = database.schema.system_setting
		return system_setting.update().where(
			and_(
				system_setting.c.resource == resource,
				system_setting.c.key == key
			)
		).values(
			value_yaml=yaml.safe_dump(value)
		)

	def _get_insert_command(self, resource, key, value):
		system_setting = database.schema.system_setting
		return system_setting.insert().values(
			resource=resource,
			key=key,
			value_yaml=yaml.safe_dump(value)
		)

	@AdminApi
	def set_website_domain_name(self, user_id, domain_name):
		WebServerSettings.domain_name = domain_name

	@AdminApi
	def set_aws_keys(self, user_id, access_key, secret_key):
		AwsSettings.aws_access_key_id = access_key
		AwsSettings.aws_secret_access_key = secret_key

	@AdminApi
	def set_instance_settings(self, user_id, instance_size, num_waiting, max_running):
		AwsSettings.instance_type = instance_size
		VerificationServerSettings.static_pool_size = num_waiting
		VerificationServerSettings.max_virtual_machine_count = max_running
