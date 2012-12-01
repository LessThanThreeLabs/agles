""" permissions.py - utility classes for handling permissions"""
from sqlalchemy import and_
from database.schema import permission, repo
from database.engine import ConnectionFactory


def has_repo_permissions(user_id, repo_id):
	query = permission.join(repo).select().where(
		and_(
			permission.c.user_id==user_id,
			repo.c.id==repo_id,
		)
	)

	with ConnectionFactory.get_sql_connection() as sqlconn:
		row = sqlconn.execute(query).first()
	if not row:
		return False
	return RepositoryPermissions.has_permissions(
		row[permission.c.permissions], RepositoryPermissions.R)

class Permissions(object):
	pass

class RepositoryPermissions(Permissions):
	""" Permissions are currently stored as bitmasks. These methods should be
	used to operate on the bitmasks to do comparisons and permissions checks.
	"""
	NONE = 0
	R = 0b1
	RW = 0b11
	RWA = 0b111

	@classmethod
	def has_permissions(cls, given_permissions, required_permissions):
		return (given_permissions & required_permissions) == required_permissions

	@classmethod
	def valid_permissions(cls):
		return [cls.NONE, cls.R, cls.RW, cls.RWA]