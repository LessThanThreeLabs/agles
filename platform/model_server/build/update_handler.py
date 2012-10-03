from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler

class Console(object):
	Stdout, Stderr = range(2)

class BuildConsoleUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildConsoleUpdateHandler, self).__init__("build", "update")

	def append_console_output(self, build_id, console_output, console=Console.Stdout):
		""" The redis keys for build output are of the form build.output:build_id:console
		:param build_id: The build id this console is relevant to.
		:param console_output: The new console output to append and store.
		:param console: The console type we are appending to.
		"""

		redis_key = "build.output:%s:%s" % (build_id, console)
		redis_conn = ConnectionFactory.get_redis_connection()
		redis_conn.rpush(redis_key, console_output)

	def flush_console_output(self, build_id, console=Console.Stdout):
		""" Flushes finalized console output to a persisted sql db.
		:param build_id: The build id this console is relevant to.
		:param console: The console type we are flushing.
		"""

		redis_key = "build.output:%s:%s" % (build_id, console)
		redis_conn = ConnectionFactory.get_redis_connection()
		complete_console_output = '\n'.join(redis_conn.lrange(redis_key, 0, -1))

		ins = schema.build_console.insert(build_id=build_id, type=console,
			console_output = complete_console_output)
		self._db_conn.execute(ins)
		redis_conn.delete(redis_key)

