import database.schema

from sqlalchemy import and_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from model_server.build_outputs import REDIS_KEY_TEMPLATE


class BuildOutputsReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildOutputsReadHandler, self).__init__("build_outputs", "read")

	def get_console_output(self, user_id, build_id, console):
		redis_key = REDIS_KEY_TEMPLATE % (build_id, console)

		redis_conn = ConnectionFactory.get_redis_connection()
		if redis_conn.exists(redis_key):
			return redis_conn.hgetall(redis_key)

		build_console = database.schema.build_console
		query = build_console.select().where(
			and_(
				build_console.c.build_id==build_id,
				build_console.c.type==console
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		lines = row[build_console.c.console_output].splitlines()
		return dict(enumerate(lines))
