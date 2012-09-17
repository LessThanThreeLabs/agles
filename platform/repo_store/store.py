# store.py -- Implements storage servers for git repositories using dulwich

"""Git repository storage servers.

Repository management is done using a modified version of dulwich,
a git implementation written in python.

* For more information on the modified dulwich, see the submodule.
"""

import os
import shutil

import zerorpc
from dulwich.repo import Repo
from redis import Redis

from util import repositories


class RepositoryStoreManager(object):
	def create_repository(self, store_name, repo_hash, repo_name):
		"""Creates a repository on the given local store.

		:param store_name: The identifier of the local store(machine) to create the repository on.
		:param repo_hash: The unique identifier for the repository being created.
		:param repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, store_name, repo_hash, repo_name):
		"""Deletes a repository on the given local store.

		:param store_name: The identifier of the local store(machine) to create the repository on.
		:param repo_hash: The unique identifier for the repository being created.
		:param repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")

	def rename_repository(self, store_name, repo_hash, old_repo_name, new_repo_name):
		"""Renames a repository on the given local store.

		:param store_name: The identifier of the local store(machine) to create the repository on.
		:param repo_hash: The unique identifier for the repository being created.
		:param old_repo_name: The name of the old repository.
		:param new_repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")


class DistributedLoadBalancingRepositoryStoreManager(RepositoryStoreManager):
	"""A manager class that manages local repository stores and forwards requests to the correct store"""

	SERVER_REPO_COUNT_NAME = "server_repository_count"
	DEFAULT_RPC_TIMEOUT = 500

	def __init__(self, managed_stores, redis_connection):
		super(DistributedLoadBalancingRepositoryStoreManager, self).__init__()
		self.managed_store_conns = {}
		self._redisdb = redis_connection
		self._register_managed_stores(managed_stores)

	@classmethod
	def create_from_settings(cls):
		"""Create an instance from the settings/store.py file"""
		from settings.store import file_system_repository_servers, distributed_store_redis_connection
		redis_connection = Redis(**distributed_store_redis_connection)
		return cls(file_system_repository_servers, redis_connection)

	def create_repository(self, store_name, repo_hash, repo_name):
		client_conn = self.managed_store_conns[store_name]
		client_conn.create_repository(repo_hash, repo_name)
		self._update_store_repo_count(store_name)

	def delete_repository(self, store_name, repo_hash, repo_name):
		client_conn = self.managed_store_conns[store_name]
		client_conn.delete_repository(repo_hash, repo_name)
		self._update_store_repo_count(store_name, -1)

	def rename_repository(self, store_name, repo_hash, old_repo_name, new_repo_name):
		client_conn = self.managed_store_conns[store_name]
		client_conn.rename_repository(repo_hash, old_repo_name, new_repo_name)

	def _register_managed_stores(self, managed_stores):
		self._initialize_store_repo_counts_if_not_exists(managed_stores.iterkeys())
		for store_name, connection_info in managed_stores.iteritems():
			self.managed_store_conns[store_name] = zerorpc.Client(connection_info, timeout=self.DEFAULT_RPC_TIMEOUT)

	def get_least_loaded_store(self):
		"""Identifies the local store that is being least utilized. For this particular class
		least utilized is defined as having the lowest number of repositories."""

		results = self._redisdb.zrange(self.SERVER_REPO_COUNT_NAME, 0, 0, score_cast_func=int)
		assert len(results) == 1
		return results[0]

	def _initialize_store_repo_counts_if_not_exists(self, store_names):
		stores_to_initialize = {}
		for store_name in store_names:
			if not self._redisdb.zscore(self.SERVER_REPO_COUNT_NAME, store_name):
				stores_to_initialize[store_name] = 0
		self._redisdb.zadd(self.SERVER_REPO_COUNT_NAME, **stores_to_initialize)

	def _update_store_repo_count(self, store_name, amount=1):
		self._redisdb.zincrby(self.SERVER_REPO_COUNT_NAME, store_name, amount)


class RepositoryStore(object):
	"""Base class for RepositoryStore"""

	def create_repository(self, repo_hash, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, repo_hash, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def rename_repository(self, repo_hash, repo_name):
		raise NotImplementedError("Subclasses should override this!")


class FileSystemRepositoryStore(RepositoryStore):
	"""Local filesystem store for server side git repositories"""

	DIR_LEVELS = 3

	def __init__(self, root_storage_directory_path):
		super(FileSystemRepositoryStore, self).__init__()
		if not os.path.exists(root_storage_directory_path):
			os.makedirs(root_storage_directory_path)
		self._root_path = root_storage_directory_path

	def create_repository(self, repo_hash, repo_name):
		"""Creates a new server side repository. Raises an exception on failure.
		We create bare repositories because they are server side.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param repo_name: The name of the new repository.
		"""
		repo_path = self._resolve_path(repo_hash, repo_name)
		if not os.path.exists(repo_path):
			os.makedirs(repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_hash, repo_path)
		Repo.init_bare(repo_path)

	def delete_repository(self, repo_hash, repo_name):
		"""Deletes a server side repository. This cannot be undone. Raises an exception on failure.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param repo_name: The name of the repository to be deleted.
		"""
		repo_path = self._resolve_path(repo_hash, repo_name)
		shutil.rmtree(repo_path)

	def rename_repository(self, repo_hash, old_name, new_name):
		"""Renames a repository. Raises an exception on failure.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param old_name: The old repository name.
		:param new_name: The new repository name.
		"""
		old_repo_path = self._resolve_path(repo_hash, old_name)
		new_repo_path = self._resolve_path(repo_hash, new_name)
		if not os.path.exists(new_repo_path):
			shutil.move(old_repo_path, new_repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_hash, new_repo_path)

	def _resolve_path(self, repo_hash, repo_name):
		repo_path = os.path.join(self._root_path,
								 repositories.to_path(repo_hash, repo_name, self.DIR_LEVELS))
		return os.path.realpath(repo_path)


class RepositoryOperationException(Exception):
	"""Base class for exception relating to repository management."""

	def __init__(self, msg=''):
		super(RepositoryOperationException, self).__init__(msg)


class RepositoryAlreadyExistsException(RepositoryOperationException):
	"""Indicates an exception occurred due to a repository already existing."""

	def __init__(self, repo_hash, existing_repo_path):
		super(RepositoryAlreadyExistsException, self).__init__(
			  'Repository with hash %s already exists at path %s' % (repo_hash, existing_repo_path))
