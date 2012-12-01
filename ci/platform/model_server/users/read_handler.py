from sqlalchemy import and_

from model_server.rpc_handler import ModelServerRpcHandler

import database.schema

from database.engine import ConnectionFactory
from util.database import to_dict


class UsersReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersReadHandler, self).__init__("users", "read")

	def _get_user_row(self, email, password_hash):
		user = database.schema.user

		query = user.select().where(
			and_(
				user.c.email==email,
				user.c.password_hash==password_hash
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row

	def get_salt(self, email):
		user = database.schema.user

		query = user.select().where(user.c.email==email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return row[user.c.salt]
		else:
			raise NoSuchUserError(email)

	def get_user_id(self, email, password_hash):
		return self.get_user(email, password_hash)['id']

	def get_user(self, email, password_hash):
		user = database.schema.user

		row = self._get_user_row(email, password_hash)
		if row:
			return to_dict(row, user.columns)
		else:
			raise NoSuchUserError(email, password_hash)

	def get_user_from_id(self, user_id):
		user = database.schema.user

		query = user.select().where(user.c.id==user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return to_dict(row, user.columns)
		else:
			raise NoSuchUserError(user_id)


class NoSuchUserError(Exception):
	pass
