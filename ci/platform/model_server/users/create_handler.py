import database.schema
import time
import util.pathgen

from sqlalchemy.exc import IntegrityError

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class UsersCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersCreateHandler, self).__init__("users", "create")

	def create_user(self, email, first_name, last_name, password_hash, salt, admin=False):
		user = database.schema.user
		ins = user.insert().values(email=email, first_name=first_name, last_name=last_name, password_hash=password_hash, salt=salt, admin=admin, created=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			try:
				result = sqlconn.execute(ins)
			except IntegrityError:
				raise UserAlreadyExistsError(email)

		user_id = result.inserted_primary_key[0]
		self.publish_event_to_admins("users", "user created", user_id=user_id, email=email, first_name=first_name, last_name=last_name,
			password_hash=password_hash, salt=salt, admin=admin, created=int(time.time()))
		return user_id

	def _generate_path(self, media_id, hash):
		return util.pathgen.to_path(hash, media_id)


class UserAlreadyExistsError(Exception):
	pass
