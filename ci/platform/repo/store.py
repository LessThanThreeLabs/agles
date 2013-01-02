# store.py -- Implements storage servers for git repositories.
"""Git repository storage servers.

Repository management is done using gitpython.
"""
import logging
import os
import re
import shutil
import socket
import sys
import yaml

import model_server

from git import GitCommandError, Repo

from bunnyrpc.client import Client
from settings.store import rpc_exchange_name
from util import pathgen


class RemoteRepositoryManager(object):

	def register_remote_store(self, repostore_id, num_repos):
		"""Registers a remote store as a managed store of this manager

		:param repostore_id: The identifier of the remote store the repository is on
		:param num_repos: The number of repos to initialize it with
		"""
		raise NotImplementedError("Subclasses should override this!")

	def merge_changeset(self, repostore_id, repo_id, repo_name, ref_to_merge, ref_to_merge_into):
		"""Merges a changeset on the remote repository with a ref.

		:param repostore_id: The identifier of the local store(machine) the
							repository is on.
		:param repo_id: The unique identifier for the repository being created.
		:param repo_name: The name of the repository.
		:param ref_to_merge: The sha ref of the changeset on the remote
							repository we want to merge.
		:param ref_to_merge_into: The ref we want to merge into.
		"""
		raise NotImplementedError("Subclasses should override this!")

	def create_repository(self, repostore_id, repo_id, repo_name):
		"""Creates a repository on the given local store.

		:param repostore_id: The identifier of the local store(machine) to create the repository on.
		:param repo_id: The unique identifier for the repository being created.
		:param repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, repostore_id, repo_id, repo_name):
		"""Deletes a repository on the given local store.

		:param repostore_id: The identifier of the local store(machine) to create the repository on.
		:param repo_id: The unique identifier for the repository being created.
		:param repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")

	def rename_repository(self, repostore_id, repo_id, old_repo_name, new_repo_name):
		"""Renames a repository on the given local store.

		:param repostore_id: The identifier of the local store(machine) to create the repository on.
		:param repo_id: The unique identifier for the repository being created.
		:param old_repo_name: The name of the old repository.
		:param new_repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")


class DistributedLoadBalancingRemoteRepositoryManager(RemoteRepositoryManager):
	"""A manager class that manages local repository stores and forwards requests to the correct store"""

	SERVER_REPO_COUNT_NAME = "server_repository_count"

	def __init__(self, redis_connection):
		super(DistributedLoadBalancingRemoteRepositoryManager, self).__init__()
		self._redisdb = redis_connection

	def register_remote_store(self, repostore_id, num_repos=0):

		self._redisdb.zadd(self.SERVER_REPO_COUNT_NAME, **{str(repostore_id): num_repos})

	def merge_changeset(self, repostore_id, repo_id, repo_name, ref_to_merge, ref_to_merge_into):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			client.merge_changeset(repo_id, repo_name, ref_to_merge, ref_to_merge_into)

	def create_repository(self, repostore_id, repo_id, repo_name):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			client.create_repository(repo_id, repo_name)
		self._update_store_repo_count(repostore_id)

	def delete_repository(self, repostore_id, repo_id, repo_name):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(rpc_exchange_name, RepositoryStore.queue_name(repostore_id)) as client:
			client.delete_repository(repo_id, repo_name)
		self._update_store_repo_count(repostore_id, -1)

	def rename_repository(self, repostore_id, repo_id, old_repo_name, new_repo_name):
		assert old_repo_name.endswith(".git")
		assert new_repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			client.rename_repository(repo_id, old_repo_name, new_repo_name)

	def get_least_loaded_store(self):
		"""Identifies the local store that is being least utilized. For this particular class
		least utilized is defined as having the lowest number of repositories."""

		results = self._redisdb.zrange(self.SERVER_REPO_COUNT_NAME, 0, 0, score_cast_func=int)
		assert len(results) == 1
		return int(results[0])  # We use repostore id's so these should all be ints

	def _update_store_repo_count(self, repostore_id, amount=1):
		self._redisdb.zincrby(self.SERVER_REPO_COUNT_NAME, str(repostore_id), amount)


class RepositoryStore(object):
	"""Base class for RepositoryStore"""
	CONFIG_FILE = ".repostore_config.yml"

	@classmethod
	def queue_name(cls, repostore_id):
		return "repostore:%d" % repostore_id

	@classmethod
	def create_config(cls, repostore_id, root_dir):
		config = {"id": repostore_id}
		config_path = os.path.join(root_dir, cls.CONFIG_FILE)
		if not os.path.exists(root_dir):
			os.makedirs(root_dir)
		with open(config_path, "w") as stream:
			yaml.dump(config, stream, default_flow_style=False)
		return config

	@classmethod
	def parse_config(cls, root_dir):
		config_path = os.path.join(root_dir, cls.CONFIG_FILE)
		with open(config_path) as config_file:
			config = yaml.load(config_file.read())
		return config

	@classmethod
	def initialize_store(cls, root_dir):
		host_name = cls._get_host_name()
		with model_server.ModelServer.rpc_connect("repos", "create") as conn:
			return conn.register_repostore(host_name, root_dir)

	@classmethod
	def update_store(cls, repostore_id, root_dir, num_repos):
		host_name = cls._get_host_name()
		with model_server.ModelServer.rpc_connect("repos", "update") as conn:
			conn.update_repostore(repostore_id, host_name, root_dir, num_repos)

	@classmethod
	def _get_host_name(cls):  # relies on Google DNS to capture own outbound ip
		sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		sock.connect(("8.8.8.8", 80))
		host_name = sock.getsockname()[0]
		sock.close()
		return host_name

	def merge_changeset(self, repo_id, repo_name, sha_to_merge, ref_to_merge_into):
		raise NotImplementedError("Subclasses should override this!")

	def create_repository(self, repo_id, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, repo_id, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def rename_repository(self, repo_id, old_repo_name, new_repo_name):
		raise NotImplementedError("Subclasses should override this!")


class FileSystemRepositoryStore(RepositoryStore):
	"""Local filesystem store for server side git repositories"""

	logger = logging.getLogger("FileSystemRepositoryStore")

	def __init__(self, root_storage_directory_path):
		super(FileSystemRepositoryStore, self).__init__()
		if not os.path.exists(root_storage_directory_path):
			os.makedirs(root_storage_directory_path)
		self._root_path = root_storage_directory_path

	def _push_forward_url(self, repo, remote_repo, ref):
		try:
			repo.git.push(remote_repo, ':'.join([ref, ref]), f=True)
		except GitCommandError:
			error_msg = "failed to push repo to github: [repo: %s, remote_repo: %s, ref: %s]" % (repo, remote_repo, ref)
			self.logger.exception(error_msg)

	def _push_forward_url_if_necessary(self, repo, repo_id, ref):
		with model_server.ModelServer.rpc_connect("repos", "read") as conn:
			remote_repo = conn.get_repo_forward_url(repo_id)

		# remote_repo is None if user doesn't have a pushback url set
		if remote_repo:
			self._push_forward_url(repo, remote_repo, ref)

	def merge_changeset(self, repo_id, repo_name, ref_to_merge, ref_to_merge_into):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		repo_path = self._resolve_path(repo_id, repo_name)
		repo = Repo(repo_path)
		repo_slave = repo.clone(repo_path + ".slave") if not os.path.exists(repo_path + ".slave") else Repo(repo_path + ".slave")
		try:
			repo_slave.git.fetch()  # update branches
			remote_branch = "origin/%s" % ref_to_merge_into  # origin/master or whatever
			remote_branch_exists = re.search("\\s+" + remote_branch + "$", repo_slave.git.branch("-r"), re.MULTILINE)
			repo_slave.git.fetch("origin", ref_to_merge)  # point FETCH_HEAD at ref to merge
			repo_slave.git.checkout("FETCH_HEAD")
			ref_sha = repo_slave.head.commit.hexsha
			checkout_branch = remote_branch if remote_branch_exists else "FETCH_HEAD"
			repo_slave.git.checkout(checkout_branch, "-B", ref_to_merge_into)
			repo_slave.git.merge("FETCH_HEAD", "-m", "Merging in %s" % ref_sha)
			repo_slave.git.push("origin", "HEAD:%s" % ref_to_merge_into)
		except GitCommandError:
			stacktrace = sys.exc_info()[2]
			error_msg = "repo: %s, ref_to_merge: %s, ref_to_merge_into: %s" % (
				repo, ref_to_merge, ref_to_merge_into)
			self.logger.info(error_msg)
			raise MergeError, error_msg, stacktrace
		finally:
			repo_slave.git.reset(hard=True)

		self._push_forward_url_if_necessary(repo, repo_id, ref_to_merge_into)

	def create_repository(self, repo_id, repo_name):
		"""Creates a new server side repository. Raises an exception on failure.
		We create bare repositories because they are server side.

		:param repo_id: A unique id assigned to each repository that is used to determine
						which directory the repository is stored under.
		:param repo_name: The name of the new repository.
		"""
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		repo_path = self._resolve_path(repo_id, repo_name)
		if not os.path.exists(repo_path):
			os.makedirs(repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_id, repo_path)
		Repo.init(repo_path, bare=True)

	def delete_repository(self, repo_id, repo_name):
		"""Deletes a server side repository. This cannot be undone. Raises an exception on failure.

		:param repo_id: A unique id assigned to each repository that is used to determine
						which directory the repository is stored under.
		:param repo_name: The name of the repository to be deleted.
		"""
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		repo_path = self._resolve_path(repo_id, repo_name)
		shutil.rmtree(repo_path)

	def rename_repository(self, repo_id, old_name, new_name):
		"""Renames a repository. Raises an exception on failure.

		:param repo_id: A unique id assigned to each repository that is used to
						determine which directory the repository is stored under.
		:param old_name: The old repository name.
		:param new_name: The new repository name.
		"""
		assert old_name.endswith(".git")
		assert new_name.endswith(".git")
		assert isinstance(repo_id, int)

		old_repo_path = self._resolve_path(repo_id, old_name)
		new_repo_path = self._resolve_path(repo_id, new_name)
		if not os.path.exists(new_repo_path):
			shutil.move(old_repo_path, new_repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_id, new_repo_path)

	def _resolve_path(self, repo_id, repo_name):
		repo_path = os.path.join(self._root_path,
									pathgen.to_path(repo_id, repo_name))
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

	def __init__(self, msg='', repo_id=None, existing_repo_path=None):
		if not msg:
			msg = 'Repository with id %d already exists at path %s' % (repo_id, existing_repo_path)
		super(RepositoryAlreadyExistsException, self).__init__(msg)
