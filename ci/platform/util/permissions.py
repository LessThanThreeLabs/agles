""" permissions.py - utility classes for handling permissions"""
import database.schema
from database.engine import ConnectionFactory


def is_admin(user_id):
	assert isinstance(user_id, int)
	user = database.schema.user

	query = user.select().where(user.c.id == user_id)
	with ConnectionFactory.get_sql_connection() as sqlconn:
		row = sqlconn.execute(query).first()
	return row[user.c.admin] and row[user.c.deleted] == 0 if row else False


def AdminApi(func):
	def wrapper(self, user_id, *args, **kwargs):
		if not is_admin(user_id):
			raise InvalidPermissionsError("%d is not an admin" % user_id)
		return func(self, user_id, *args, **kwargs)
	return wrapper


class InvalidPermissionsError(Exception):
	pass
