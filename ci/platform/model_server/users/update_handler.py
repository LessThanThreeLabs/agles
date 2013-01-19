import hashlib

from sqlalchemy import and_

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class UsersUpdateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersUpdateHandler, self).__init__("users", "update")

	def add_ssh_pubkey(self, user_id, alias, ssh_key):
		ssh_key = " ".join(ssh_key.split()[:2])  # Retain only type and key
		ssh_pubkey = schema.ssh_pubkey
		ins = ssh_pubkey.insert().values(user_id=user_id, alias=alias, ssh_key=ssh_key)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)
		self.publish_event("users", user_id, "ssh pubkey added", alias=alias, ssh_key=ssh_key)

	def remove_ssh_pubkey(self, user_id, alias):
		ssh_pubkey = schema.ssh_pubkey
		delete = ssh_pubkey.delete().where(
			and_(
				ssh_pubkey.c.user_id==user_id,
				ssh_pubkey.c.alias==alias
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(delete)
		self.publish_event("users", user_id, "ssh pubkey removed", alias=alias, ssh_key=None)

	def update_user(self, user_id, information):
		user = schema.user
		update = user.update().where(user.c.id==user_id).values(**information)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user updated", user_id=user_id,
			information=information)

	def reset_password(self, email, new_password):
		user = schema.user
		salt_query = user.select().where(user.c.email==email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(salt_query).first()
		if row:
			salt = row[user.c.salt]
		else:
			raise NoSuchUserError(email)
		# latin-1 is an arbitrary full-byte fixed length character encoding, which thus does not ruin our original salt
		update = user.update().where(user.c.email==email).values(password_hash=hashlib.sha512(salt.encode('latin-1') + new_password.encode('utf8')).hexdigest())
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)


class NoSuchUserError(Exception):
	pass
