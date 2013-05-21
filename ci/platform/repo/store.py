# store.py -- Implements storage servers for git repositories.
"""Git repository storage servers.

Repository management is done using gitpython.
"""
from __future__ import print_function
import os
import re
import shutil
import socket
import sys
import time
import yaml

import eventlet

import model_server

from git import GitCommandError, Repo, refs

from bunnyrpc.client import Client
from settings.store import StoreSettings
from util import greenlets, pathgen
from util.log import Logged

MINUTE = 60


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

	def create_repository(self, repostore_id, repo_id, repo_name, private_key):
		"""Creates a repository on the given local store.

		:param repostore_id: The identifier of the local store(machine) to create the repository on.
		:param repo_id: The unique identifier for the repository being created.
		:param repo_name: The name of the new repository.
		:param private_key: An RSA private key for the repository to push to other forward urls
		"""
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, repostore_id, repo_id, repo_name):
		"""Deletes a repository on the given local store.

		:param repostore_id: The identifier of the local store(machine) to create the repository on.
		:param repo_id: The unique identifier for the repository being created.
		:param repo_name: The name of the new repository.
		"""
		raise NotImplementedError("Subclasses should override this!")

	def push_force(self, repostore_id, repo_id, repo_name, from_target, to_target):
		"""Force pushes the repository to the forwarding url

		:param repostore_id: The identifier of the local machine the repo is on
		:param repo_id: The unique id of the RepositoryStore
		:param repo_name: The name of the repo
		:param from_target: The ref we're pushing to target
		:param to_target: The ref to push
		"""
		raise NotImplementedError("Subclasses should override this!")

	def force_delete(self, repostore_id, repo_id, repo_name, target):
		"""Force pushes the repository to the forwarding url

		:param repostore_id: The identifier of the local machine the repo is on
		:param repo_id: The unique id of the RepositoryStore
		:param repo_name: The name of the repo
		:param target: The ref to delete
		"""
		raise NotImplementedError("Subclasses should override this!")

	def store_pending(self, repostore_id, repo_id, repo_name, sha, commit_id):
		"""Stores the given sha as a pending ref based on the commit id

		:param repostore_id: The identifier of the local machine the repo is on
		:param repo_id: The unique id of the RepositoryStore
		:param repo_name: The name of the repo
		:param sha: The SHA-1 ref of the commit to store
		:param commit_id: The pending id to store the SHA-1 ref at
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

		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			client.merge_changeset(repo_id, repo_name, ref_to_merge, ref_to_merge_into)

	def create_repository(self, repostore_id, repo_id, repo_name, private_key):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			client.create_repository(repo_id, repo_name, private_key)
		self._update_store_repo_count(repostore_id)

	def delete_repository(self, repostore_id, repo_id, repo_name):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id)) as client:
			client.delete_repository(repo_id, repo_name)
		self._update_store_repo_count(repostore_id, -1)

	def push_force(self, repostore_id, repo_id, repo_name, from_target, to_target):
		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			client.push_force(repo_id, repo_name, from_target, to_target)

	def force_delete(self, repostore_id, repo_id, repo_name, target):
		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			return client.force_delete(repo_id, repo_name, target)

	def store_pending(self, repostore_id, repo_id, repo_name, sha, commit_id):
		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
			return client.store_pending(repo_id, repo_name, sha, commit_id)

	def rename_repository(self, repostore_id, repo_id, old_repo_name, new_repo_name):
		assert old_repo_name.endswith(".git")
		assert new_repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(repostore_id), globals=globals()) as client:
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

	def __init__(self, repostore_id):
		self.repostore_id = repostore_id
		eventlet.spawn_n(self._ip_address_updater)

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
			yaml.safe_dump(config, stream, default_flow_style=False)
		return config

	@classmethod
	def parse_config(cls, root_dir):
		config_path = os.path.join(root_dir, cls.CONFIG_FILE)
		with open(config_path) as config_file:
			config = yaml.safe_load(config_file.read())
		return config

	@classmethod
	def initialize_store(cls, root_dir):
		ip_address = cls._get_ip_address()
		with model_server.rpc_connect("repos", "create") as conn:
			return conn.register_repostore(ip_address, root_dir)

	@classmethod
	def update_store(cls, repostore_id, root_dir, num_repos):
		ip_address = cls._get_ip_address()
		with model_server.rpc_connect("repos", "update") as conn:
			conn.update_repostore(repostore_id, ip_address, root_dir, num_repos)

	@classmethod
	def _get_ip_address(cls):
		return socket.gethostbyname(socket.gethostname())

	def _ip_address_updater(self):
		while True:
			try:
				ip_address = self._get_ip_address()
				with model_server.rpc_connect("repos", "update") as conn:
					conn.update_repostore_ip(self.repostore_id, ip_address)
			except:
				self.logger.error("ip address updater greenlet failed unexpectedly", exc_info=True)
			time.sleep(5 * MINUTE)

	def merge_changeset(self, repo_id, repo_name, sha_to_merge, ref_to_merge_into):
		raise NotImplementedError("Subclasses should override this!")

	def create_repository(self, repo_id, repo_name, private_key):
		raise NotImplementedError("Subclasses should override this!")

	def delete_repository(self, repo_id, repo_name):
		raise NotImplementedError("Subclasses should override this!")

	def push_force(self, repo_id, repo_name, from_target, to_target):
		raise NotImplementedError("Subclasses should override this!")

	def force_delete(self, repo_id, repo_name, target):
		raise NotImplementedError("Subclasses should override this!")

	def store_pending(self, repo_id, repo_name, sha, commit_id):
		raise NotImplementedError("Subclasses should override this!")

	def rename_repository(self, repo_id, old_repo_name, new_repo_name):
		raise NotImplementedError("Subclasses should override this!")


@Logged()
class FileSystemRepositoryStore(RepositoryStore):
	"""Local filesystem store for server side git repositories"""

	NUM_RETRIES = 4
	GIT_WITH_PRIVATE_KEY_SCRIPT = 'koality-git-with-private-key'
	if hasattr(sys, 'real_prefix'):  # We're in a virtualenv python, so point at the locally-installed script
		GIT_WITH_PRIVATE_KEY_SCRIPT = os.path.join(sys.prefix, 'bin', GIT_WITH_PRIVATE_KEY_SCRIPT)

	def __init__(self, repostore_id, root_storage_directory_path):
		super(FileSystemRepositoryStore, self).__init__(repostore_id)
		if not os.path.exists(root_storage_directory_path):
			os.makedirs(root_storage_directory_path)
		self._root_path = root_storage_directory_path

	def merge_refs(self, repo_slave, ref_to_merge, ref_to_merge_into):
		self.logger.info("Attempting to merge refs %s into %s on repo %s" % (ref_to_merge, ref_to_merge_into, repo_slave))
		try:
			repo_slave.git.fetch()  # update branches
			remote_branch = "origin/%s" % ref_to_merge_into  # origin/master or whatever
			remote_branch_exists = re.search("\\s+" + remote_branch + "$", repo_slave.git.branch("-r"), re.MULTILINE)
			repo_slave.git.fetch("origin", ref_to_merge)  # point FETCH_HEAD at ref to merge
			repo_slave.git.checkout("FETCH_HEAD")
			ref_sha = repo_slave.head.commit.hexsha
			checkout_branch = remote_branch if remote_branch_exists else "FETCH_HEAD"
			repo_slave.git.checkout(checkout_branch, "-B", ref_to_merge_into)
			original_head = repo_slave.head.commit.hexsha
			repo_slave.git.merge("FETCH_HEAD", "-m", "Merging in %s" % ref_sha)
			repo_slave.git.push("origin", "HEAD:%s" % ref_to_merge_into)
			return original_head
		except GitCommandError:
			stacktrace = sys.exc_info()[2]
			error_msg = "Merge failed for repo_slave (potential to retry): %s, ref_to_merge: %s, ref_to_merge_into: %s" % (
				repo_slave, ref_to_merge, ref_to_merge_into)
			self.logger.info(error_msg, exc_info=True)
			raise MergeError, error_msg, stacktrace
		finally:
			repo_slave.git.reset(hard=True)

	def _update_from_forward_url(self, repo_slave, remote_repo, ref_to_update):
		try:
			ref_sha = self._update_branch_from_forward_url(repo_slave, remote_repo, ref_to_update)
			remote_branch = "origin/%s" % ref_to_update  # origin/master or whatever
			repo_slave.git.checkout(remote_branch, "-B", ref_to_update)
			repo_slave.git.merge("FETCH_HEAD", "-m", "Merging in %s" % ref_sha)
			repo_slave.git.push("origin", "HEAD:%s" % ref_to_update)
		except GitCommandError:
			stacktrace = sys.exc_info()[2]
			error_msg = "Attempting to update/merge from forward url. repo_slave: %s, ref_to_update: %s" % (repo_slave, ref_to_update)
			self.logger.info(error_msg, exc_info=True)
			raise MergeError, error_msg, stacktrace
		finally:
			repo_slave.git.reset(hard=True)

	def _update_branch_from_forward_url(self, repo_slave, remote_repo, ref_to_update):
			# branch has to exist on the non-slave (not forward url) because we're trying to push it
			remote_branch = "origin/%s" % ref_to_update  # origin/master or whatever
			self._fetch_with_private_key(repo_slave, remote_repo, ref_to_update)
			repo_slave.git.checkout("FETCH_HEAD")
			ref_sha = repo_slave.head.commit.hexsha
			repo_slave.git.checkout(remote_branch, "-B", ref_to_update)
			return ref_sha

	def _push_merge_retry(self, repo, repo_slave, remote_repo, ref_to_merge_into, original_head):
		i = 0
		while True:
			i += 1
			try:
				self._push_with_private_key(repo, remote_repo, ':'.join([ref_to_merge_into, ref_to_merge_into]))
			except GitCommandError:
				if i >= self.NUM_RETRIES:
					stacktrace = sys.exc_info()[2]
					error_msg = "Retried too many times, repo: %s, ref_to_merge_into: %s" % (repo, ref_to_merge_into)
					self.logger.warn(error_msg, exc_info=True)
					self._reset_repository_head(repo, repo_slave, ref_to_merge_into, original_head)
					raise PushForwardError, error_msg, stacktrace
				time.sleep(1)
				self._update_from_forward_url(repo_slave, remote_repo, ref_to_merge_into)
			except:
				self.logger.error("Push Forwarding failed due to unexpected error", exc_info=True)
				self._reset_repository_head(repo, repo_slave, ref_to_merge_into, original_head)
				raise
			else:
				break

	def _push_with_private_key(self, repo, *args, **kwargs):
		self.logger.info("Attempting to push repo %s to forward url with args: %s, kwargs: %s" % (repo, str(args), str(kwargs)))
		execute_args = ['git', 'push'] + list(args) + repo.git.transform_kwargs(**kwargs)
		repo.git.execute(execute_args, env={'GIT_SSH': self.GIT_WITH_PRIVATE_KEY_SCRIPT, 'GIT_SSH_TIMEOUT': '120'})

	def _fetch_with_private_key(self, repo, *args, **kwargs):
		self.logger.info("Attempting to fetch to repo %s" % repo)
		execute_args = ['git', 'fetch'] + list(args) + repo.git.transform_kwargs(**kwargs)
		repo.git.execute(execute_args, env={'GIT_SSH': self.GIT_WITH_PRIVATE_KEY_SCRIPT, 'GIT_SSH_TIMEOUT': '120'})

	def _reset_repository_head(self, repo, repo_slave, ref_to_reset, original_head):
		try:
			repo_slave.git.push('origin', '%s' % ':'.join([original_head, ref_to_reset]), force=True)
		except GitCommandError as e:
			error_msg = "Unable to reset repo: %s ref: %s to commit: %s" % (repo, ref_to_reset, original_head)
			self.logger.error(error_msg)
			raise e

	def merge_changeset(self, repo_id, repo_name, ref_to_merge, ref_to_merge_into):
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		repo_path = self._resolve_path(repo_id, repo_name)
		repo = Repo(repo_path)
		repo_slave = repo.clone(repo_path + ".slave") if not os.path.exists(repo_path + ".slave") else Repo(repo_path + ".slave")

		with model_server.rpc_connect("repos", "read") as conn:
			remote_repo = conn.get_repo_forward_url(repo_id)
		original_head = self.merge_refs(repo_slave, ref_to_merge, ref_to_merge_into)
		self._push_merge_retry(repo, repo_slave, remote_repo, ref_to_merge_into, original_head)

	def create_repository(self, repo_id, repo_name, private_key):
		"""Creates a new server side repository. Raises an exception on failure.
		We create bare repositories because they are server side.

		:param repo_id: A unique id assigned to each repository that is used to determine
						which directory the repository is stored under.
		:param repo_name: The name of the new repository.
		:param private_key: RSA private key for pushing/pulling to other repos
		"""
		assert repo_name.endswith(".git")
		assert isinstance(repo_id, int)

		repo_path = self._resolve_path(repo_id, repo_name)
		private_key_path = repo_path + ".id_rsa"
		if not os.path.exists(repo_path):
			os.makedirs(repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_id, repo_path)
		Repo.init(repo_path, bare=True)
		with open(private_key_path, 'w') as f:
			os.chmod(private_key_path, 0600)
			print(private_key, file=f)

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
		os.remove(repo_path + ".id_rsa")

	def push_force(self, repo_id, repo_name, from_target, to_target):
		"""Pushes forward to the url with a force"""
		repo_path = self._resolve_path(repo_id, repo_name)
		repo = Repo(repo_path)

		with model_server.rpc_connect("repos", "read") as conn:
			remote_repo = conn.get_repo_forward_url(repo_id)

		self.logger.info("Pushing branch %s:%s on %s" % (from_target, to_target, repo_path))
		try:
			self._push_with_private_key(repo, remote_repo, ':'.join([from_target, to_target]), force=True)
		except GitCommandError:
			self.logger.warn("A git error occurred on force push", exc_info=True)
			raise

	def force_delete(self, repo_id, repo_name, target):
		if self._remote_branch_exists:
			try:
				self.push_force(repo_id, repo_name, "", target)
			except GitCommandError as e:
				self.logger.warn("Force delete encountered an error", exc_info=True)
				self._update_branch(repo_id, repo_name, target)
				return e.stderr
		self._delete_branch(repo_id, repo_name, target)
		return None

	def _update_branch(self, repo_id, repo_name, target):
		try:
			self.logger.debug("updating local branch %s on repo %d" % (target, repo_id))
			with model_server.rpc_connect("repos", "read") as conn:
				remote_repo = conn.get_repo_forward_url(repo_id)
			repo_path = self._resolve_path(repo_id, repo_name)
			repo = Repo(repo_path)
			repo_slave = repo.clone(repo_path + ".slave") if not os.path.exists(repo_path + ".slave") else Repo(repo_path + ".slave")
			self._update_branch_from_forward_url(repo_slave, remote_repo, target)
			repo_slave.git.push("origin", ":".join([target, target]), force=True)
		except GitCommandError:
			self.logger.warn("Failed to update branch.", exc_info=True)

	def _delete_branch(self, repo_id, repo_name, target):
		""" This assumes the branch exists"""
		self.logger.debug("deleting local branch %s on repo %d" % (target, repo_id))
		repo_path = self._resolve_path(repo_id, repo_name)
		repo = Repo(repo_path)
		repo_slave = repo.clone(repo_path + ".slave") if not os.path.exists(repo_path + ".slave") else Repo(repo_path + ".slave")
		try:
			self._push_with_private_key(repo_slave, "origin", ':'.join(["", target]), force=True)
		except GitCommandError:
			self.logger.warn("Failed to delete local branch", exc_info=True)

	def _remote_branch_exists(self, repo_id, repo_name, branch):
		with model_server.rpc_connect("repos", "read") as conn:
			remote_repo = conn.get_repo_forward_url(repo_id)

		repo_path = self._resolve_path(repo_id, repo_name)
		repo = Repo(repo_path)
		repo.git.fetch(remote_repo)
		remote_branch = "origin/%s" % branch
		remote_branch_exists = re.search("\\s+" + remote_branch + "$", repo.git.branch("-r"), re.MULTILINE)
		return remote_branch_exists

	def store_pending(self, repo_id, repo_name, sha, commit_id):
		repo_path = self._resolve_path(repo_id, repo_name)
		repo = Repo(repo_path)

		with model_server.rpc_connect("repos", "read") as conn:
			remote_repo = conn.get_repo_forward_url(repo_id)

		self._fetch_with_private_key(repo, remote_repo)

		try:
			refs.SymbolicReference.create(repo, 'refs/pending/%d' % commit_id, sha)
		except:
			self.logger.critical("Failed to create pending ref %d for sha %s" % (commit_id, sha), exc_info=True)
			raise

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
		repo_path = os.path.join(self._root_path, pathgen.to_path(repo_id, repo_name))
		return os.path.realpath(repo_path)


class RepositoryOperationException(Exception):
	"""Base class for exception relating to repository management."""

	def __init__(self, msg=''):
		super(RepositoryOperationException, self).__init__(msg)


class PushForwardError(RepositoryOperationException):
	"""Indicates that an error occured while attempting to push to a forward url"""

	def __init__(self, msg=''):
		super(PushForwardError, self).__init__(msg)


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
