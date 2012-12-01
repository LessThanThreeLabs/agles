from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class UsersUpdateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersUpdateHandler, self).__init__("users", "update")

	def register_ssh_pubkey(self, user_id, alias, ssh_key):
		ssh_pubkey = schema.ssh_pubkey
		ins = ssh_pubkey.insert().values(user_id=user_id, alias=alias, ssh_key=ssh_key)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)
		self.publish_event("users", user_id, "ssh pubkey added", alias=alias, ssh_key=ssh_key)

	def delete_ssh_pubkey(self, user_id, alias):
		ssh_key = schema.ssh_pubkey
		delete = ssh_pubkey.delete().where(ssh_key.c.alias==alias)
		with ConnectionFactory.get_sql_connection as sqlconn:
			sqlconn.execute(delete)
		self.publish_event("users", user_id, "ssh pubkey removed", alias=alias, ssh_key=None)
