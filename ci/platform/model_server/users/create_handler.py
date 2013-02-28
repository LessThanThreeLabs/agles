import database.schema
import util.pathgen

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class UsersCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersCreateHandler, self).__init__("users", "create")

	def create_user(self, information):
		assert "email" in information
		assert "first_name" in information
		assert "last_name" in information
		assert "salt" in information
		assert "password_hash" in information

		user = database.schema.user
		ins = user.insert().values(**information)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		user_id = result.inserted_primary_key[0]
		self.publish_event("global", None, "user created", user_id=user_id, information=information)
		return result.inserted_primary_key[0]

	def _generate_path(self, media_id, hash):
		return util.pathgen.to_path(hash, media_id)
