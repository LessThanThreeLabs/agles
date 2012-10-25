from model_server.rpc_handler import ModelServerRpcHandler


class UserReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UserReadHandler, self).__init__("repo", "read")

	def get_user_id(self, email, password_hash):
		pass

	def get_user(self, email, password_hash):
		pass

	def get_user_from_id(self, user_id):
		pass