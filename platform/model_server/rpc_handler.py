from bunnyrpc.server import Server
from database.engine import ConnectionFactory


class ModelServerRpcHandler(object):
	@property
	def _db_conn(self):
		return ConnectionFactory.get_sql_connection()

	def __init__(self, rpc_noun, rpc_verb):
		self.rpc_noun = rpc_noun
		self.rpc_verb = rpc_verb
		self.rpc_queue_name = "-".join(["rpc", rpc_noun, rpc_verb])

	def get_server(self, channel=None):
		rpc_handler = Server(self)
		rpc_handler.bind("model-rpc", [self.rpc_queue_name], channel=channel)
		return rpc_handler

	def start(self):
		self.get_server().run()
