import yaml

from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import AdminApi


class SystemSettingsReadHandler(ModelServerRpcHandler):

	def __init__(self):
		super(SystemSettingsReadHandler, self).__init__("system_settings", "read")

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
			return yaml.safe_load(row[system_setting.c.value_yaml]) if row else None

	@AdminApi
	def get_website_domain_name(self, user_id):
		return self.get_setting("webserver", "domain_name")

	@AdminApi
	def get_aws_keys(self, user_id):
		aws_access_key_id = self.get_setting("aws", "aws_access_key_id")
		aws_secret_access_key = self.get_setting("aws", "aws_secret_access_key")
		return {"access_key": aws_access_key_id, "secret_key": aws_secret_access_key}

	@AdminApi
	def get_allowed_instance_sizes(self, user_id):
		return ['m1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge',
			'm3.xlarge', 'm3.2xlarge', 'c1.medium', 'c1.xlarge', 'hi1.4xlarge', 'hs1.8xlarge']

	@AdminApi
	def get_instance_settings(self, user_id):
		instance_size = self.get_setting("aws", "instance_size")
		num_waiting = self.get_setting("verification_server", "static_pool_size")
		max_running = self.get_setting("verification_server", "virtual_machine_count")
		return {"instance_size": instance_size, "num_waiting": num_waiting, "max_running": max_running}
