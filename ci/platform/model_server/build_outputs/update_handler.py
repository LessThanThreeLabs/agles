from sqlalchemy import and_

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from model_server.build_outputs import ConsoleType, REDIS_KEY_TEMPLATE


class BuildOutputsUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildOutputsUpdateHandler, self).__init__("build_outputs", "update")

	def append_console_line(self, build_id, line_num, line, type, subtype=""):
		""" The redis keys for build output are of the form build.output:build_id:type:subtype
		:param build_id: The build id this console is relevant to.
		:param line_num: The line number we're appending
		:param line: The line to append and store.
		:param type: The console type we are appending to.
		:param subtype: The console subtype we are appending to.
		"""

		redis_key = REDIS_KEY_TEMPLATE % (build_id, type, subtype)
		redis_conn = ConnectionFactory.get_redis_connection()
		redis_conn.hset(redis_key, line_num, line)

	def _compact_output(self, redis_conn, redis_key):
		line_dict = redis_conn.hgetall(redis_key)
		_, lines = zip(*sorted(line_dict.iteritems(),
			key=lambda tup: int(tup[0]))) if line_dict else (None, [])
		complete_console_output = '\n'.join(lines)
		return complete_console_output

	def flush_console_output(self, build_id, type, subtype=""):
		""" Flushes finalized console output to a persisted sql db.
		:param build_id: The build id this console is relevant to.
		:param type: The console type we are flushing.
		:param subtype: The console subtype we are flushing.
		"""
		build_console = schema.build_console

		redis_key = REDIS_KEY_TEMPLATE % (build_id, type, subtype)
		redis_conn = ConnectionFactory.get_redis_connection()
		complete_console_output = self._compact_output(redis_conn, redis_key)

		whereclause = and_(
			build_console.c.build_id==build_id,
			build_console.c.type==type,
			build_console.c.subtype==subtype
		)

		query = build_console.select().where(whereclause)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			statement = build_console.update().values(
				console_output=complete_console_output).where(whereclause)
		else:
			statement = build_console.insert().values(build_id=build_id, type=type,
				subtype=subtype, console_output=complete_console_output)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(statement)
		redis_conn.delete(redis_key)
