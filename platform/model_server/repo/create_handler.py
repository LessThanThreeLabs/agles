import os

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class RepoCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(RepoCreateHandler, self).__init__("repo", "create")

	def create_repo(self, repo_name, machine_id, default_permissions):
		# This is a stub that only does things that are needed for testing atm.
		# It needs to be completed
		repo = database.schema.repo
		repo_hash = os.urandom(16).encode('hex')
		ins = repo.insert().values(name=repo_name, hash=repo_hash, machine_id=machine_id, default_permissions=default_permissions)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		return result.inserted_primary_key[0]
