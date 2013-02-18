import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ReposUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ReposUpdateHandler, self).__init__("repos", "update")

	def update_repostore(self, repostore_id, host_name, root_dir, num_repos):
		repostore = database.schema.repostore
		query = repostore.select().where(repostore.c.id==repostore_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			assert row[repostore.c.host_name] == host_name
			assert row[repostore.c.repositories_path] == root_dir

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.register_remote_store(repostore_id, num_repos=num_repos)

	def force_push(self, repo_id, user_id, target):
		schema = database.schema
		query = schema.repo.select().where(schema.repo.c.id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			repostore_id = row[schema.repo.c.repostore_id]
			repo_name = row[schema.repo.c.name]

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.push_force(repostore_id, repo_id, repo_name, target)

	def set_forward_url(self, user_id, repo_id, forward_url):
		repo = database.schema.repo

		# A repo should already exist
		update = repo.update().where(repo.c.id==repo_id).values(forward_url=forward_url)
		with ConnectionFactory.get_sql_connection() as sqlconn:
				sqlconn.execute(update)
		self.publish_event("repos", repo_id, "forward url updated", forward_url=forward_url)


class NoSuchUserError(Exception):
	pass


class InvalidActionError(Exception):
	pass
