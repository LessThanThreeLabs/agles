from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import RepositoryPermissions, InvalidPermissionsError


class ReposUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ReposUpdateHandler, self).__init__("repos", "update")

	def add_member(self, user_id, email, repo_id):
		repo = database.schema.repo
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_joined_permission_row(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))
		repo_hash = row[repo.c.hash]
		repo_permissions = row[repo.c.default_permissions]

		with ConnectionFactory.get_sql_connection() as sqlconn:
			invited_user = sqlconn.execute(user.select().where(user.c.email==email)).first()
			if not invited_user:
				raise NoSuchUserError("email: %s" % email)
			invited_user_id = invited_user[user.c.id]
			sqlconn.execute(permission.insert().values(user_id=invited_user_id, repo_hash=repo_hash, permissions=repo_permissions))

		self.publish_event("repos", repo_id, "member added", email=email, first_name=invited_user[user.c.first_name],
			last_name=invited_user[user.c.last_name], permissions=repo_permissions)

	def change_member_permissions(self, user_id, email, repo_id, permissions):
		repo = database.schema.repo
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_joined_permission_row(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))
		repo_hash = row[repo.c.hash]

		user_query = user.select().where(user.c.email==email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			user_row = sqlconn.execute(user_query).first()
		if not user_row:
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		target_user_id = user_row[user.c.id]
		if target_user_id == user_id:
			raise InvalidActionError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		del_query = permission.delete().where(and_(
			permission.c.user_id==target_user_id,
			permission.c.repo_hash==repo_hash)
		)
		ins = permission.insert().values(user_id=target_user_id, repo_hash=repo_hash, permissions=permissions)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(del_query)
			sqlconn.execute(ins)

		self.publish_event("repos", repo_id, "member permissions changed", email=email, permissions=permissions)

	def remove_member(self, user_id, email, repo_id):
		repo = database.schema.repo
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_joined_permission_row(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))
		repo_hash = row[repo.c.hash]

		user_query = user.select().where(user.c.email==email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			user_row = sqlconn.execute(user_query).first()
		if not user_row:
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		target_user_id = user_row[user.c.id]
		if target_user_id == user_id:
			raise InvalidActionError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		del_query = permission.delete().where(and_(
			permission.c.user_id==target_user_id,
			permission.c.repo_hash==repo_hash)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(del_query)

		self.publish_event("repos", repo_id, "member removed", email=email)

	# TODO: Once repo hash is removed, clean all this up
	def _get_repo_joined_permission_row(self, user_id, repo_id):
		repo = database.schema.repo
		permission = database.schema.permission

		query = repo.join(permission).select().apply_labels().where(
			and_(
				repo.c.id==repo_id,
				permission.c.user_id==user_id
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return sqlconn.execute(query).first()

#####################
# Github Integration
#####################

	def set_corresponding_github_repo_url(self, repo_id, github_repo_url):
		github_repo_url_map = schema.github_repo_url_map
		ins = github_repo_url_map.insert().values(
			repo_id=repo_id,
			github_url=github_repo_url
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)


class NoSuchUserError(Exception):
	pass


class InvalidActionError(Exception):
	pass
