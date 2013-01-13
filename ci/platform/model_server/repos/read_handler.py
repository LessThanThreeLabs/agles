from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from shared.constants import VerificationUser
from util.sql import to_dict
from util.permissions import RepositoryPermissions, InvalidPermissionsError


class ReposReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposReadHandler, self).__init__("repos", "read")

	def get_repo_uri(self, commit_id):
		commit = database.schema.commit
		repo = database.schema.repo

		repo_id_query = commit.select().where(
			commit.c.id==commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(repo_id_query).first()
		if not row:
			return None
		repo_id = row[commit.c.repo_id]

		query = repo.select().where(repo.c.id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.uri] if row else None

	def get_repo_name(self, repo_id):
		repo = database.schema.repo
		query = repo.select().where(repo.c.id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.name] if row else None

	def get_repo_attributes(self, requested_repo_uri):
		repo = database.schema.repo
		repostore = database.schema.repostore

		query = repo.join(repostore).select().apply_labels().where(repo.c.uri==requested_repo_uri)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row_result = sqlconn.execute(query).first()
		if not row_result:
			return None
		return row_result[repostore.c.id], row_result[repostore.c.host_name], row_result[repostore.c.repositories_path], row_result[repo.c.id], row_result[repo.c.name]

	def get_user_id_from_public_key(self, key):
		ssh_pubkey = database.schema.ssh_pubkey
		query = ssh_pubkey.select().where(ssh_pubkey.c.ssh_key==key)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[ssh_pubkey.c.user_id] if row else None

	def get_commit_attributes(self, commit_id):
		commit = database.schema.commit

		query = commit.select().where(commit.c.id==commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return row[commit.c.repo_id], row[commit.c.user_id], row[commit.c.message], row[commit.c.timestamp]
		else:
			return None

	def get_permissions(self, user_id, repo_id):
		assert isinstance(user_id, int)
		if user_id == VerificationUser.id:
			return RepositoryPermissions.RWA
		permission = database.schema.permission

		query = permission.select().where(
			and_(
				permission.c.user_id==user_id,
				permission.c.repo_id==repo_id
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[permission.c.permissions] if row else RepositoryPermissions.NONE

	#################
	# Front end API #
	#################

	def _get_visible_repos(self, user_id):
		repo = database.schema.repo
		permission = database.schema.permission

		query = repo.join(permission).select().apply_labels().where(permission.c.user_id==user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)
		return filter(lambda row: RepositoryPermissions.has_permissions(
			row[permission.c.permissions], RepositoryPermissions.RW), rows)

	def get_visible_repo_menuoptions(self, user_id, repo_id):
		repo = database.schema.repo
		permission = database.schema.permission

		query = repo.join(permission).select().apply_labels().where(
			and_(
				permission.c.user_id==user_id,
				repo.c.id==repo_id
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		options = {
			'default': 'changes',
			#'options': ['source', 'changes', 'settings']
			'options': ['changes']
		}

		if row and RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			options['options'].append('admin')
		return options

	def get_writable_repo_ids(self, user_id):
		repo = database.schema.repo

		visible_rows = self._get_visible_repos(user_id)
		return map(lambda row: row[repo.c.id], visible_rows)

	def get_writable_repos(self, user_id):
		repo = database.schema.repo

		visible_rows = self._get_visible_repos(user_id)
		return map(lambda row: to_dict(row, repo.columns, tablename=repo.name),
			visible_rows)

	def get_repo_from_id(self, user_id, repo_id):
		repo = database.schema.repo

		permissions = self.get_permissions(user_id, repo_id)
		if not RepositoryPermissions.has_permissions(permissions, RepositoryPermissions.R):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		query = repo.select().where(repo.c.id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		assert row is not None
		return to_dict(row, repo.columns)

	def get_members_with_permissions(self, user_id, repo_id):
		user = database.schema.user
		permission = database.schema.permission

		permissions = self.get_permissions(user_id, repo_id)
		if not RepositoryPermissions.has_permissions(permissions, RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		query = user.join(permission).select().apply_labels().where(permission.c.repo_id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [dict(to_dict(row, user.columns, tablename=user.name).items() + [(permission.c.permissions.name, row[permission.c.permissions])])
				for row in sqlconn.execute(query)]

#########################
# Host Repo Integration #
#########################

	def get_repo_forward_url(self, repo_id):
		repo = database.schema.repo

		query = repo.select().where(repo.c.id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			return row[repo.c.forward_url] if row else None
