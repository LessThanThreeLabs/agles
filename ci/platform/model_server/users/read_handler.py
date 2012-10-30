from sqlalchemy import and_

from model_server.rpc_handler import ModelServerRpcHandler

import database.schema

from database.engine import ConnectionFactory
from util.database import to_dict

class UserReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UserReadHandler, self).__init__("users", "read")

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

	def get_user_id(self, email, password_hash):
		user = database.schema.user

		row = self._get_user_row(email, password_hash)
		return row[user.c.id] if row else None

	def get_user(self, email, password_hash):
		user = database.schema.user

		row = self._get_user_row(email, password_hash)
		return to_dict(row, user.columns)

	def get_user_from_id(self, user_id):
		user = database.schema.user

		query = user.select().where(user.c.id==user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return to_dict(row, user.columns)
