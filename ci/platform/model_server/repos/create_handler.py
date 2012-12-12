import os
import uuid

from sqlalchemy import and_

import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import RepositoryPermissions


class ReposCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposCreateHandler, self).__init__("repos", "create")

	def create_repo(self, user_id, repo_name, default_permissions):
		try:
			repo_name += ".git"
			#TODO: REMOVE REPO HASH!!!!!!!!!!
			repo_hash = os.urandom(16).encode('hex')
			store_name = self._create_repo_on_filesystem(repo_hash, repo_name)
			repo_id = self._create_repo_in_db(repo_hash, repo_name, store_name, default_permissions)
			self._grant_permissions(user_id, repo_hash, RepositoryPermissions.RWA)
			self.publish_event("global", None, "repo added",
				repo_id=repo_id, repo_name=repo_name, repo_hash=repo_hash, default_permissions=default_permissions)
			return repo_id
		except Exception, e:
			# do logging here to say we need to fix inconsistencies between
			# the db and fs
			raise e

	def _create_repo_on_filesystem(self, repo_hash, repo_name):
		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		store_name = manager.get_least_loaded_store()
		manager.create_repository(store_name, repo_hash, repo_name)
		return store_name

	def _create_repo_in_db(self, repo_hash, repo_name, store_name, default_permissions):
		repo = database.schema.repo
		repostore = database.schema.repostore
		query = repostore.select().where(repostore.c.uri==store_name)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			repostore_id = sqlconn.execute(query).first()[repostore.c.id]

			ins = repo.insert().values(name=repo_name, hash=repo_hash, repostore_id=repostore_id, default_permissions=default_permissions)
			result = sqlconn.execute(ins)
		repo_id = result.inserted_primary_key[0]
		return repo_id

	def _grant_permissions(self, user_id, repo_hash, permissions):
		permission = database.schema.permission
		ins = permission.insert().values(
			user_id=user_id,
			repo_hash=repo_hash,
			permissions=permissions)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)

	def register_repostore(self, host_name, root_dir):
		#TODO: We don't need a store name. Just use id. This is a large refactor
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
