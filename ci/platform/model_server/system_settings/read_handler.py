import yaml

from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


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
