import os
import uuid

from sqlalchemy import and_

import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ReposCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposCreateHandler, self).__init__("repos", "create")

	def create_repo(self, repo_name, repostore_id, default_permissions):
		# This is a stub that only does things that are needed for testing atm.
		# It needs to be completed
		repo = database.schema.repo
		repo_hash = os.urandom(16).encode('hex')
		ins = repo.insert().values(name=repo_name, hash=repo_hash, repostore_id=repostore_id, default_permissions=default_permissions)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		repo_id = result.inserted_primary_key[0]
		self.publish_event(repo_id=repo_id, repo_name=repo_name, repo_hash=repo_hash, default_permissions=default_permissions)
		return repo_id

	def register_repostore(self, host_name, root_dir):
		store_name = uuid.uuid1().hex
		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.register_remote_store(store_name)

		repostore = database.schema.repostore
		query = repostore.select().where(
			and_(
				repostore.c.host_name==host_name,
				repostore.c.repositories_path==root_dir
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			statement = repostore.update().where(
				and_(
					repostore.c.host_name==host_name,
					repostore.c.repositories_path==root_dir
				)
			).values(uri=store_name)
		else:
			statement = repostore.insert().values(uri=store_name, host_name=host_name, repositories_path=root_dir)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(statement)
		return store_name
