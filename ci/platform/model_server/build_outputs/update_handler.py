from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from model_server.build_outputs import Console, REDIS_KEY_TEMPLATE


class BuildOutputsUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildOutputsUpdateHandler, self).__init__("build_outputs", "update")

	def append_console_line(self, build_id, line_num, line, console=Console.General, subcategory=""):
		""" The redis keys for build output are of the form build.output:build_id:console
		:param build_id: The build id this console is relevant to.
		:param line_num: The line number we're appending
		:param line: The line to append and store.
		:param console: The console type we are appending to.
		"""

		redis_key = REDIS_KEY_TEMPLATE % (build_id, console, subcategory)
		redis_conn = ConnectionFactory.get_redis_connection()
		redis_conn.hset(redis_key, line_num, line)

	def flush_console_output(self, build_id, console=Console.General, subcategory=""):
		""" Flushes finalized console output to a persisted sql db.
		:param build_id: The build id this console is relevant to.
		:param console: The console type we are flushing.
		"""

		redis_key = REDIS_KEY_TEMPLATE % (build_id, console, subcategory)
		redis_conn = ConnectionFactory.get_redis_connection()
		line_dict = redis_conn.hgetall(redis_key)
		_, lines = zip(*sorted(line_dict.iteritems())) if line_dict else (None, [])
		complete_console_output = '\n'.join(lines)

		ins = schema.build_console.insert().values(build_id=build_id, type=console,
			subcategory=subcategory, console_output=complete_console_output)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)
		redis_conn.delete(redis_key)
