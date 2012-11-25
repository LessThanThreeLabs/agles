from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy.sql import select
from util.database import to_dict
from util.permissions import RepositoryPermissions

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
		query = select([repostore.c.uri, repostore.c.host_name, repostore.c.repositories_path, repo.c.hash, repo.c.name], from_obj=[
            uri_repo_map.select().where(uri_repo_map.c.uri==requested_repo_uri).alias().join(repo).join(repostore)])
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row_result = sqlconn.execute(query).first()
		if not row_result:
			return None
		return row_result[repostore.c.uri], row_result[repostore.c.host_name], row_result[repostore.c.repositories_path], row_result[repo.c.hash], row_result[repo.c.name]

	def get_user_id_from_public_key(self, key):
		ssh_pubkeys = database.schema.ssh_pubkeys
		query = ssh_pubkeys.select().where(ssh_pubkeys.c.ssh_key==key)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[ssh_pubkeys.c.user_id] if row else None

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

		default_menuoptions = ['source', 'builds', 'settings']
		if row and RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			return default_menuoptions + ['admin']
		else:
			return default_menuoptions

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
		permission = database.schema.permission

		query = repo.join(permission).select().apply_labels().where(
			and_(
				repo.c.id==repo_id,
				permission.c.user_id==user_id
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.R):
			return {}
		else:
			return to_dict(row, repo.columns, tablename=repo.name)
