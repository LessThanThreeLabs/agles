import os

from sqlalchemy import and_

import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import RepositoryPermissions
from util.pathgen import to_clone_path


class ReposCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposCreateHandler, self).__init__("repos", "create")

	def create_repo(self, user_id, repo_name, default_permissions):
		try:
			repo_name += ".git"
			manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
			repostore_id = manager.get_least_loaded_store()
			uri = self._transpose_to_uri(repo_name)

			# Set entries in db
			repo_id = self._create_repo_in_db(user_id, repo_name, uri, repostore_id, default_permissions)
			self._grant_permissions(user_id, repo_id, RepositoryPermissions.RWA)
			# make filesystem changes
			self._create_repo_on_filesystem(manager, repostore_id, repo_id, repo_name)
			
			self.publish_event("global", None, "repo added",
				repo_id=repo_id, repo_name=repo_name, default_permissions=default_permissions)
			return repo_id
		except Exception, e:
			# do logging here to say we need to fix inconsistencies between
			# the db and fs
			raise e

	def _create_repo_on_filesystem(self, manager, repostore_id, repo_id, repo_name):
		manager.create_repository(repostore_id, repo_id, repo_name)

	def _create_repo_in_db(self, user_id, repo_name, uri, repostore_id, default_permissions):
		repo = database.schema.repo
		repostore = database.schema.repostore
		query = repostore.select().where(repostore.c.id==repostore_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			repostore_id = sqlconn.execute(query).first()[repostore.c.id]
			ins = repo.insert().values(name=repo_name, uri=uri, repostore_id=repostore_id, default_permissions=default_permissions)
			result = sqlconn.execute(ins)
		repo_id = result.inserted_primary_key[0]
		return repo_id

	def _grant_permissions(self, user_id, repo_id, permissions):
		permission = database.schema.permission
		ins = permission.insert().values(
			user_id=user_id,
			repo_id=repo_id,
			permissions=permissions)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)

	def _transpose_to_uri(self, repo_name):
		user = database.schema.user
		with ConnectionFactory.get_sql_connection() as sqlconn:
			query = user.select().where(user.c.id==user_id)
			email = sqlconn.execute(query).first()[user.c.email]

		return to_clone_path(email, repo_name)

	def register_repostore(self, host_name, root_dir):
		repostore = database.schema.repostore
		ins = repostore.insert().values(host_name=host_name, repositories_path=root_dir)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
			repostore_id = result.inserted_primary_key[0]

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.register_remote_store(repostore_id)
		return repostore_id
