from sqlalchemy import and_

from model_server.rpc_handler import ModelServerRpcHandler

import database.schema

from database.engine import ConnectionFactory
from util.sql import to_dict


class UsersReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersReadHandler, self).__init__("users", "read")

	def get_password_hash_and_salt(self, user_id):
		user = database.schema.user

		query = user.select().where(user.c.id == user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return to_dict(row, [user.c.password_hash, user.c.salt])
		else:
			raise NoSuchUserError(user_id)

	def email_in_use(self, email):
		try:
			self.get_salt(email)
			return True
		except NoSuchUserError:
			return False

	def get_user_id(self, email):
		return self.get_user(email)['id']

	def get_user(self, email):
		user = database.schema.user

		query = user.select().where(user.c.email == email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return to_dict(row, user.columns)
		else:
			raise NoSuchUserError(email)

	def get_user_from_id(self, user_id):
		user = database.schema.user

		query = user.select().where(user.c.id == user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return to_dict(row, user.columns)
		else:
			raise NoSuchUserError(user_id)

	def get_ssh_keys(self, user_id):
		ssh_pubkey = database.schema.ssh_pubkey

		query = ssh_pubkey.select().where(ssh_pubkey.c.user_id == user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			keys = [to_dict(row, ssh_pubkey.columns) for row in sqlconn.execute(query)]
		return keys


class NoSuchUserError(Exception):
	pass
