""" permissions.py - utility classes for handling permissions"""
import database.schema
from database.engine import ConnectionFactory


def is_admin(user_id):
	user = database.schema.user

	query = user.select().where(user.c.id == user_id)
	with ConnectionFactory.get_sql_connection() as sqlconn:
		row = sqlconn.execute(query).first()
		return row[user.c.admin]


class InvalidPermissionsError(Exception):
	pass
