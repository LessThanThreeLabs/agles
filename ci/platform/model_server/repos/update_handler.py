import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ReposUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ReposUpdateHandler, self).__init__("repos", "update")

	def update_repostore(self, repostore_id, ip_address, root_dir, num_repos):
		self.update_repostore_ip(repostore_id, ip_address)
		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
		manager.register_remote_store(repostore_id, num_repos=num_repos)

	def update_repostore_ip(self, repostore_id, ip_address):
		repostore = database.schema.repostore
		query = repostore.select().where(repostore.c.id == repostore_id)
		update = repostore.update().where(repostore.c.id == repostore_id).values(ip_address=ip_address)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			sqlconn.execute(update)

	def _get_repostore_id_and_repo_name(self, repo_id):
		schema = database.schema
		query = schema.repo.select().where(schema.repo.c.id == repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			repostore_id = row[schema.repo.c.repostore_id]
			repo_name = row[schema.repo.c.name]
		return dict(repostore_id=repostore_id, repo_name=repo_name)

	def force_push(self, repo_id, user_id, from_target, to_target):
		info = self._get_repostore_id_and_repo_name(repo_id)
		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
		manager.push(info['repostore_id'], repo_id, info['repo_name'], from_target, to_target, force=True)

	def force_delete(self, repo_id, user_id, target):
		info = self._get_repostore_id_and_repo_name(repo_id)

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
		return manager.force_delete(info['repostore_id'], repo_id, info['repo_name'], target)

	def set_forward_url(self, user_id, repo_id, forward_url):
		repo = database.schema.repo

		# A repo should already exist
		update = repo.update().where(repo.c.id == repo_id).values(forward_url=forward_url)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("repos", repo_id, "forward url updated", forward_url=forward_url)


class NoSuchUserError(Exception):
	pass


class InvalidActionError(Exception):
	pass
