from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from shared.constants import VerificationUser
from sqlalchemy.sql import select
from util.sql import to_dict
from util.permissions import RepositoryPermissions, InvalidPermissionsError


class ReposReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposReadHandler, self).__init__("repos", "read")

	def get_repo_uri(self, commit_id):
		commit = database.schema.commit
		repo = database.schema.repo
		uri_repo_map = database.schema.uri_repo_map

		repo_id_query = commit.select().where(
			commit.c.id==commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(repo_id_query).first()
		if not row:
			return None
		repo_hash = row[commit.c.repo_hash]

		query = repo.join(
            uri_repo_map).select().where(repo.c.hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[uri_repo_map.c.uri] if row else None

	def get_repo_name(self, repo_hash):
		repo = database.schema.repo
		query = repo.select().where(repo.c.hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.name] if row else None

	def get_repo_attributes(self, requested_repo_uri):
		uri_repo_map = database.schema.uri_repo_map
		repo = database.schema.repo
		repostore = database.schema.repostore
		query = select([repostore.c.id, repostore.c.host_name, repostore.c.repositories_path, repo.c.hash, repo.c.name], from_obj=[
			uri_repo_map.select().where(uri_repo_map.c.uri==requested_repo_uri).alias().join(repo).join(repostore)])
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row_result = sqlconn.execute(query).first()
		if not row_result:
			return None
		return row_result[repostore.c.id], row_result[repostore.c.host_name], row_result[repostore.c.repositories_path], row_result[repo.c.hash], row_result[repo.c.name]

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

	def get_permissions(self, user_id, repo_hash):
		assert isinstance(user_id, int)
		if user_id == VerificationUser.id:
			return RepositoryPermissions.RWA
		permission = database.schema.permission

		query = permission.select().where(
			and_(
				permission.c.user_id==user_id,
				permission.c.repo_hash==repo_hash
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
			'options': ['source', 'changes', 'settings']
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

	def get_repo_from_id(self, user_id, repo_id):
		repo = database.schema.repo
		permission = database.schema.permission

		row = self._get_repo_joined_permission_row(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.R):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))
		return to_dict(row, repo.columns, tablename=repo.name)

	def get_clone_url(self, user_id, repo_id):
		permission = database.schema.permission
		uri_repo_map = database.schema.uri_repo_map

		row = self._get_repo_joined_permission_row(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.R):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		uri_query = uri_repo_map.select().where(uri_repo_map.c.repo_id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(uri_query).first()
			assert row is not None
			return row[uri_repo_map.c.uri]

	def get_members_with_permissions(self, user_id, repo_id):
		repo = database.schema.repo
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_joined_permission_row(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))
		repo_hash = row[repo.c.hash]

		query = user.join(permission).select().apply_labels().where(permission.c.repo_hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [dict(to_dict(row, user.columns, tablename=user.name).items() + [(permission.c.permissions.name, row[permission.c.permissions])])
				for row in sqlconn.execute(query)]

######################
# Github Integration #
######################

	def get_corresponding_github_repo_url(self, repo_hash):
		repo = database.schema.repo
		github_repo_url_map = database.schema.github_repo_url_map

		query = github_repo_url_map.join(repo).select().where(
			repo.c.hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			return row[github_repo_url_map.c.github_url] if row else None
