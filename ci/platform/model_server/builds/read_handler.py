import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict


class BuildsReadHandler(ModelServerRpcHandler):
	def __init__(self, channel=None):
		super(BuildsReadHandler, self).__init__("builds", "read", channel)

	def get_build_from_id(self, build_id):
		build = database.schema.build

		query = build.select().where(build.c.id == build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return to_dict(row, build.columns)
