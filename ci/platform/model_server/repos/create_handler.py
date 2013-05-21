import time

import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.log import Logged
from util.pathgen import to_clone_path
from util.permissions import AdminApi


@Logged()
class ReposCreateHandler(ModelServerRpcHandler):
	KEYBITS = 1024

	def __init__(self):
		super(ReposCreateHandler, self).__init__("repos", "create")

	@AdminApi
	def create_repo(self, user_id, repo_name, forward_url):
		if not repo_name:
			raise RepositoryCreateError("repo_name cannot be empty")
		try:
			repo_name += ".git"
			manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
			repostore_id = manager.get_least_loaded_store()
			uri = repo_name  # email addresses in uri don't make sense anymore
			current_time = int(time.time())

			# Set entries in db
			repo_id = self._create_repo_in_db(
				user_id,
				repo_name,
				uri,
				repostore_id,
				forward_url,
				current_time)
			# make filesystem changes
			self._create_repo_on_filesystem(manager, repostore_id, repo_id, repo_name)

			self.publish_event_to_all("users", "repository added", repo_id=repo_id, repo_name=repo_name, created=current_time)
			return repo_id
		except Exception as e:
			error_msg = "failed to create repo: [user_id: %d, repo_name: %s]" % (user_id, repo_name)
			self.logger.exception(error_msg)
			raise RepositoryCreateError(e)

	def _create_repo_on_filesystem(self, manager, repostore_id, repo_id, repo_name):
		manager.create_repository(repostore_id, repo_id, repo_name)

	def _create_repo_in_db(self, user_id, repo_name, uri, repostore_id, forward_url, current_time):
		repo = database.schema.repo
		repostore = database.schema.repostore
		query = repostore.select().where(repostore.c.id == repostore_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			repostore_id = sqlconn.execute(query).first()[repostore.c.id]
			ins = repo.insert().values(
				name=repo_name,
				uri=uri,
				repostore_id=repostore_id,
				forward_url=forward_url,
				created=current_time)
			result = sqlconn.execute(ins)

		repo_id = result.inserted_primary_key[0]
		return repo_id

	def _transpose_to_uri(self, user_id, repo_name):
		user = database.schema.user
		query = user.select().where(user.c.id == user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			email = sqlconn.execute(query).first()[user.c.email]

		return to_clone_path(email, repo_name)

	def register_repostore(self, ip_address, root_dir):
		repostore = database.schema.repostore
		ins = repostore.insert().values(ip_address=ip_address, repositories_path=root_dir)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
			repostore_id = result.inserted_primary_key[0]

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.register_remote_store(repostore_id)
		return repostore_id


class RepositoryCreateError(Exception):
	pass
