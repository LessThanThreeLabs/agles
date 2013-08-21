from sqlalchemy import and_

from model_server.rpc_handler import ModelServerRpcHandler

import database.schema

from database.engine import ConnectionFactory
from util.sql import to_dict
from util.permissions import AdminApi


class UsersReadHandler(ModelServerRpcHandler):
	def __init__(self, channel=None):
		super(UsersReadHandler, self).__init__("users", "read", channel)

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
			self.get_user(email)
			return True
		except NoSuchUserError:
			return False

	@AdminApi
	def get_all_users(self, user_id):
		return self._get_all_users()

	def _get_all_users(self):
		user = database.schema.user

		query = user.select().where(and_(
			user.c.deleted == 0,
			user.c.id >= 1000))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)
		return [to_dict(row, user.columns) for row in rows]

	def get_user_count(self):
		return len(self._get_all_users())

	def get_user_id(self, email):
		return self.get_user(email)['id']

	def get_user(self, email):
		user = database.schema.user

		query = user.select().where(
			and_(
				user.c.email == email,
				user.c.deleted == 0
			)
		)
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

	def can_hear_user_events(self, user_id, id_to_listen_to):
		user = self.get_user_from_id(user_id)
		if user["deleted"] != 0:
			return False
		return True


class NoSuchUserError(Exception):
	pass
