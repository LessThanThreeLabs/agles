import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy.sql import select


class RepoReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(RepoReadHandler, self).__init__("repo", "read")

	def get_repo_uri(self, commit_id):
		commit = database.schema.commit
		repo = database.schema.repo
		uri_repo_map = database.schema.uri_repo_map

		repo_id_query = commit.select().where(
			commit.c.id==commit_id)
		row = self._db_conn.execute(repo_id_query).first()
		if not row:
			return None
		repo_hash = row[commit.c.repo_hash]

		query = repo.join(
            uri_repo_map).select().where(
			repo.c.hash==repo_hash)
		row = self._db_conn.execute(query).first()
		if not row:
			return None
		return row[uri_repo_map.c.uri]

	def get_repo_name(self, repo_hash):
		repo = database.schema.repo
		query = repo.select().where(repo.c.hash==repo_hash)
		row = self._db_conn.execute(query).first()
		if row:
			return row[repo.c.name]
		else:
			return None

	def get_repo_attributes(self, requested_repo_uri):
		uri_repo_map = database.schema.uri_repo_map
		repo = database.schema.repo
		machine = database.schema.machine
		query = select([machine.c.uri, repo.c.hash, repo.c.name], from_obj=[
            uri_repo_map.select().where(uri_repo_map.c.uri==requested_repo_uri).alias().join(repo).join(machine)])
		row_result = self._db_conn.execute(query).first()
		return row_result[machine.c.uri], row_result[repo.c.hash], row_result[repo.c.name]

	def get_user_id_from_public_key(self, key):
		ssh_pubkeys = database.schema.ssh_pubkeys
		query = ssh_pubkeys.select().where(ssh_pubkeys.c.ssh_key==key)
		row = self._db_conn.execute(query).first()
		return row[ssh_pubkeys.c.user_id] if row else None

	def get_commit_attributes(self, commit_id):
		commit = database.schema.commit

		query = commit.select().where(
			commit.c.id==commit_id)
		row = self._db_conn.execute(query).first()
		if row:
			return row[commit.c.repo_id], row[commit.c.user_id], row[commit.c.message], row[commit.c.timestamp]
		else:
			return None

	def get_permissions(self, user_id, repo_hash):
		permission = database.schema.permission
		repo = database.schema.repo

		query = permission.select().where(permission.c.user_id==user_id).where(permission.c.repo_hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row: return row[permission.c.level]

		query = repo.select().where(repo.c.hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.default_permissions] if row else None
