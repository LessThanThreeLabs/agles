import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy.sql import select


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
		machine = database.schema.machine
		query = select([machine.c.uri, repo.c.hash, repo.c.name], from_obj=[
            uri_repo_map.select().where(uri_repo_map.c.uri==requested_repo_uri).alias().join(repo).join(machine)])
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row_result = sqlconn.execute(query).first()
		return row_result[machine.c.uri], row_result[repo.c.hash], row_result[repo.c.name]

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
		repo = database.schema.repo

		query = permission.select().where(permission.c.user_id==user_id).where(permission.c.repo_hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row: return row[permission.c.level]

		query = repo.select().where(repo.c.hash==repo_hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.default_permissions] if row else None


	#################
	# Front end API #
	#################


	def get_repo_ids(self, user_id):
		repo = database.schema.repo


	def get_repos(self, user_id):
		pass

	def get_repo_from_id(self, user_id, repo_id):
		pass

