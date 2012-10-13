# store.py -- Implements storage servers for git repositories.
"""Git repository storage servers.

Repository management is done using gitpython.
"""

import os
import shutil
import sys

from git import GitCommandError, Repo

from bunnyrpc.client import Client
from database.engine import ConnectionFactory
from settings.store import rpc_exchange_name, filesystem_repository_servers
from util import pathgen


class RemoteRepositoryManager(object):
	def merge_changeset(self, store_name, repo_hash, repo_name, ref_to_merge, ref_to_merge_into):
		"""Merges a changeset on the remote repository with a ref.

		:param store_name: The identifier of the local store(machine) the
						   repository is on.
		:param repo_hash: The unique identifier for the repository being created.
		:param repo_name: The name of the repository.
		:param ref_to_merge: The sha ref of the changeset on the remote
							 repository we want to merge.
		:param ref_to_merge_into: The ref we want to merge into.
		"""
		raise NotImplementedError("Subclasses should override this!")

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


class DistributedLoadBalancingRemoteRepositoryManager(RemoteRepositoryManager):
	"""A manager class that manages local repository stores and forwards requests to the correct store"""

	SERVER_REPO_COUNT_NAME = "server_repository_count"
	DEFAULT_RPC_TIMEOUT = 500

	def __init__(self, filesystem_stores, redis_connection):
		super(DistributedLoadBalancingRemoteRepositoryManager, self).__init__()
		self._redisdb = redis_connection
		self._register_filesystem_stores(filesystem_stores)

	@classmethod
	def create_from_settings(cls):
		"""Create an instance from the settings/store.py file"""
		return cls(filesystem_repository_servers, ConnectionFactory.get_redis_connection())

	def merge_changeset(self, store_name, repo_hash, repo_name, ref_to_merge, ref_to_merge_into):
		assert repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		with Client(rpc_exchange_name, store_name, globals=globals()) as client:
			client.merge_changeset(repo_hash, repo_name, ref_to_merge, ref_to_merge_into)

	def create_repository(self, store_name, repo_hash, repo_name):
		assert repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		with Client(rpc_exchange_name, store_name, globals=globals()) as client:
			client.create_repository(repo_hash, repo_name)
		self._update_store_repo_count(store_name)

	def delete_repository(self, store_name, repo_hash, repo_name):
		assert repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		with Client(rpc_exchange_name, store_name) as client:
			client.delete_repository(repo_hash, repo_name)
		self._update_store_repo_count(store_name, -1)

	def rename_repository(self, store_name, repo_hash, old_repo_name, new_repo_name):
		assert old_repo_name.endswith(".git")
		assert new_repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		with Client(rpc_exchange_name, store_name, globals=globals()) as client:
			client.rename_repository(repo_hash, old_repo_name, new_repo_name)

	def _register_filesystem_stores(self, filesystem_stores):
		self._initialize_store_repo_counts_if_not_exists(filesystem_stores)

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

	def merge_changeset(self, repo_hash, repo_name, sha_to_merge, ref_to_merge_into):
		raise NotImplementedError("Subclasses should override this!")

	def create_repository(self, repo_hash, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, repo_hash, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def rename_repository(self, repo_hash, old_repo_name, new_repo_name):
		raise NotImplementedError("Subclasses should override this!")


class FileSystemRepositoryStore(RepositoryStore):
	"""Local filesystem store for server side git repositories"""

	def __init__(self, root_storage_directory_path):
		super(FileSystemRepositoryStore, self).__init__()
		if not os.path.exists(root_storage_directory_path):
			os.makedirs(root_storage_directory_path)
		self._root_path = root_storage_directory_path

	def merge_changeset(self, repo_hash, repo_name, ref_to_merge, ref_to_merge_into):
		assert repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		repo_path = self._resolve_path(repo_hash, repo_name)
		repo = Repo(repo_path)
		repo_slave = repo.clone(repo_path + ".slave") if not os.path.exists(repo_path + ".slave") else Repo(repo_path + ".slave")
		try:
			repo_slave.git.checkout(ref_to_merge_into)
			repo_slave.git.pull()
			repo_slave.git.fetch("origin", ref_to_merge)
			repo_slave.git.merge("FETCH_HEAD")
			repo_slave.git.push("origin", "HEAD:%s" % ref_to_merge_into)
		except GitCommandError, e:
			stacktrace = sys.exc_info()[2]
			error_msg = "repo: %s, ref_to_merge: %s, ref_to_merge_into: %s" % (
				repo, ref_to_merge, ref_to_merge_into)
			raise MergeError, error_msg, stacktrace
		finally:
			repo_slave.git.reset(hard=True)


	def create_repository(self, repo_hash, repo_name):
		"""Creates a new server side repository. Raises an exception on failure.
		We create bare repositories because they are server side.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param repo_name: The name of the new repository.
		"""
		assert repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		repo_path = self._resolve_path(repo_hash, repo_name)
		if not os.path.exists(repo_path):
			os.makedirs(repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_hash, repo_path)
		Repo.init(repo_path, bare=True)

	def delete_repository(self, repo_hash, repo_name):
		"""Deletes a server side repository. This cannot be undone. Raises an exception on failure.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param repo_name: The name of the repository to be deleted.
		"""
		assert repo_name.endswith(".git")
		assert isinstance(repo_hash, str)

		repo_path = self._resolve_path(repo_hash, repo_name)
		shutil.rmtree(repo_path)

	def rename_repository(self, repo_hash, old_name, new_name):
		"""Renames a repository. Raises an exception on failure.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param old_name: The old repository name.
		:param new_name: The new repository name.
		"""
		assert old_name.endswith(".git")
		assert new_name.endswith(".git")
		assert isinstance(repo_hash, str)

		old_repo_path = self._resolve_path(repo_hash, old_name)
		new_repo_path = self._resolve_path(repo_hash, new_name)
		if not os.path.exists(new_repo_path):
			shutil.move(old_repo_path, new_repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_hash, new_repo_path)

	def _resolve_path(self, repo_hash, repo_name):
		repo_path = os.path.join(self._root_path,
								 pathgen.to_path(repo_hash, repo_name))
		return os.path.realpath(repo_path)


class RepositoryOperationException(Exception):
	"""Base class for exception relating to repository management."""

	def __init__(self, msg=''):
		super(RepositoryOperationException, self).__init__(msg)

class MergeError(RepositoryOperationException):
	"""Indicates an exception occurred during an attempted merge."""

	def __init__(self, msg=''):
		super(MergeError, self).__init__(msg)

class RepositoryAlreadyExistsException(RepositoryOperationException):
	"""Indicates an exception occurred due to a repository already existing."""

	def __init__(self, msg='', repo_hash=None, existing_repo_path=None):
		if not msg:
			msg = 'Repository with hash %s already exists at path %s' % (repo_hash, existing_repo_path)
		super(RepositoryAlreadyExistsException, self).__init__(msg)
