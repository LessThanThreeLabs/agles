import re
import time

import database.schema
import model_server
import repo.store

from sqlalchemy import and_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from settings.store import StoreSettings
from util.log import Logged
from util.permissions import AdminApi


@Logged()
class ReposCreateHandler(ModelServerRpcHandler):
	KEYBITS = 1024

	def __init__(self, channel=None):
		super(ReposCreateHandler, self).__init__("repos", "create", channel)

	@AdminApi
	def create_repo(self, user_id, repo_name, forward_url, repo_type):
		if not repo_name:
			raise RepositoryCreateError("repo_name cannot be empty")
		elif re.match('^[-_a-zA-Z0-9]+$', repo_name) is None:
			raise RepositoryCreateError("repo_name must contain only letters, numbers, dashes, and underscores")
		try:
			max_repo_count = StoreSettings.max_repository_count
			if max_repo_count is not None:
				query = database.schema.repo.select().where(database.schema.repo.c.deleted == 0)
				with ConnectionFactory.get_sql_connection() as sqlconn:
					repo_count = sqlconn.execute(query).rowcount
				if repo_count >= max_repo_count:
					raise RepositoryCreateError("Already have the maximum allowed number of repositories (%d)" % max_repo_count)
			uri = repo_name  # email addresses in uri don't make sense anymore
			if repo_type == 'git':
				uri += '.git'
			elif repo_type == 'hg':
				if not forward_url.startswith('ssh://'):
					forward_url = 'ssh://%s' % forward_url
			manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
			repostore_id = manager.get_least_loaded_store()
			current_time = int(time.time())

			# Set entries in db
			repo_id = self._create_repo_in_db(
				user_id,
				repo_name,
				uri,
				repostore_id,
				forward_url,
				current_time,
				repo_type)
			# make filesystem changes
			self._create_repo_on_filesystem(manager, repostore_id, repo_id, repo_name)

			self.publish_event_to_all("users", "repository added", repo_id=repo_id, repo_name=repo_name, forward_url=forward_url, created=current_time)
			return repo_id
		except repo.store.BadRepositorySetupError as e:
			with model_server.rpc_connect('repos', 'delete') as repos_delete_handler:
				repos_delete_handler.delete_repo(user_id, repo_id)
			raise e
		except RepositoryAlreadyExistsError as e:
			self.logger.warn('Repository already exists: [user_id %d, repo_name: %s]' % (user_id, repo_name))
			raise e
		except RepositoryCreateError as e:
			error_msg = "failed to create repo: [user_id: %d, repo_name: %s]" % (user_id, repo_name)
			self.logger.exception(error_msg)
			raise e
		except Exception as e:
			error_msg = "failed to create repo: [user_id: %d, repo_name: %s]" % (user_id, repo_name)
			self.logger.exception(error_msg)
			raise RepositoryCreateError(e)

	def _create_repo_on_filesystem(self, manager, repostore_id, repo_id, repo_name):
		manager.create_repository(repostore_id, repo_id, repo_name)

	def _create_repo_in_db(self, user_id, repo_name, uri, repostore_id, forward_url, current_time, repo_type):
		repo = database.schema.repo
		repostore = database.schema.repostore
		repostore_query = repostore.select().where(repostore.c.id == repostore_id)
		existing_repo_query = repo.select().where(
			and_(
				repo.c.name == repo_name,
				repo.c.deleted == 0
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			repostore_id = sqlconn.execute(repostore_query).first()[repostore.c.id]
			if sqlconn.execute(existing_repo_query).rowcount > 0:
				raise RepositoryAlreadyExistsError(repo_name)
			ins = repo.insert().values(
				name=repo_name,
				uri=uri,
				repostore_id=repostore_id,
				forward_url=forward_url,
				created=current_time,
				type=repo_type)
			result = sqlconn.execute(ins)

		repo_id = result.inserted_primary_key[0]
		return repo_id

	def register_repostore(self, ip_address, root_dir):
		repostore = database.schema.repostore
		ins = repostore.insert().values(ip_address=ip_address, repositories_path=root_dir)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
			repostore_id = result.inserted_primary_key[0]

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
		manager.register_remote_store(repostore_id)
		return repostore_id

	@AdminApi
	def create_github_repo(self, user_id, repo_name, github_repo_name, forward_url):
		github_repo_metadata = database.schema.github_repo_metadata

		repo_id = self.create_repo(user_id, repo_name, forward_url, 'git')

		insert_github_metadata = github_repo_metadata.insert().values(
			repo_id=repo_id,
			github_repo_name=github_repo_name,
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(insert_github_metadata)

		return repo_id


class RepositoryCreateError(Exception):
	pass


class RepositoryAlreadyExistsError(RepositoryCreateError):
	pass
