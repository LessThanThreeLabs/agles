import os
import uuid

import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ReposCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposCreateHandler, self).__init__("repos", "create")

	def create_repo(self, repo_name, machine_id, default_permissions):
		# This is a stub that only does things that are needed for testing atm.
		# It needs to be completed
		repo = database.schema.repo
		repo_hash = os.urandom(16).encode('hex')
		ins = repo.insert().values(name=repo_name, hash=repo_hash, machine_id=machine_id, default_permissions=default_permissions)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		return result.inserted_primary_key[0]

	def register_repostore(self):
		store_name = uuid.uuid1().hex
		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.register_remote_store(store_name)
		return store_name
