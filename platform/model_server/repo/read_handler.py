import database.schema

from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy.sql import select


class RepoReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(RepoReadHandler, self).__init__("repo", "read")

	def get_repo_address(self, repo_hash):
		repo = database.schema.repo
		uri_repo_map = database.schema.uri_repo_map
		query = repo.join(
            uri_repo_map).select().where(
			repo.c.hash==repo_hash)
		row = self._db_conn.execute(query).first()
		if row:
			return row[uri_repo_map.c.uri]
		else:
			return None

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

	def verify_public_key(self, key):
		ssh_pubkeys = database.schema.ssh_pubkeys
		query = ssh_pubkeys.select().where(ssh_pubkeys.c.ssh_key==key)
		row = self._db_conn.execute(query).first()
		if row:
			return row[ssh_pubkeys.c.user_id]
		else:
			return None
