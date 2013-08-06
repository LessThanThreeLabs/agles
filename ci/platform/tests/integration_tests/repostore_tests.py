import os
import shutil

from os.path import exists

import model_server

from nose.tools import *
from git import Repo
from repo.store import FileSystemRepositoryStore, MergeError

from database import schema
from database.engine import ConnectionFactory
from settings.store import StoreSettings
from util.pathgen import to_path
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RepoStoreTestMixin, RabbitMixin


class RepoStoreTests(BaseIntegrationTest, ModelServerTestMixin, RepoStoreTestMixin, RabbitMixin):
	TEST_DIR = '/tmp'

	@classmethod
	def setup_class(cls):
		super(RepoStoreTests, cls).setup_class()
		cls._purge_queues()
		repodir = os.path.join(RepoStoreTests.TEST_DIR, 'repositories')
		shutil.rmtree(repodir, ignore_errors=True)
		os.mkdir(repodir)

	@classmethod
	def teardown_class(cls):
		super(RepoStoreTests, cls).teardown_class()
		repodir = os.path.join(RepoStoreTests.TEST_DIR, 'repositories')
		shutil.rmtree(repodir)

	def setUp(self):
		class NonIpUpdatingFileSystemRepositoryStore(FileSystemRepositoryStore):
			def _ip_address_updater(self):
				pass

		super(RepoStoreTests, self).setUp()
		self.repodir = os.path.join(RepoStoreTests.TEST_DIR, 'repositories')
		self.store = NonIpUpdatingFileSystemRepositoryStore(1, self.repodir)
		self.repo_id = 1
		self.repo_path = os.path.join(
			self.repodir,
			to_path(self.repo_id, "repo.git"))
		self._start_model_server()

		StoreSettings.ssh_private_key = 'NotARealPrivateKey'

		self.repostore_id = self._create_repo_store()
		self.remote_repo_path = os.path.join(self.repodir, "remote_repo.git")
		Repo.init(self.remote_repo_path, bare=True)
		with model_server.rpc_connect("repos", "create") as model_rpc:
			model_rpc._create_repo_in_db(self.repo_id, "repo", "repo_uri", self.repostore_id, self.remote_repo_path, 0, "git")

	def tearDown(self):
		super(RepoStoreTests, self).tearDown()
		self._stop_model_server()
		self._cleardir(self.repodir)
		self._purge_queues()

	def _cleardir(self, dirpath):
		for filename in os.listdir(dirpath):
			filepath = os.path.join(dirpath, filename)
			try:
				shutil.rmtree(filepath)
			except OSError:
				os.remove(filepath)

	def test_repo_create(self):
		assert_false(exists(self.repo_path), msg="Repository should not exist.")
		self.store.create_repository(self.repo_id, "repo")
		assert_true(exists(self.repo_path), msg="Repository does not exist.")

	def test_repo_create_remove(self):
		self.store.create_repository(self.repo_id, "repo")
		assert_true(exists(self.repo_path), msg="Repository was not deleted.")
		self.store.delete_repository(self.repo_id, "repo")
		assert_false(exists(self.repo_path), msg="Repository was not deleted.")

	def test_merge_pass(self):
		self.store.create_repository(self.repo_id, "repo")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")

		self._modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		repo_slave = bare_repo.clone(self.repo_path + ".slave")
		self.store.git_merge_refs(repo_slave, "refs/pending/1", "master")

	def test_merge_fail(self):
		self.store.create_repository(self.repo_id, "repo")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")
		self._modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit])

		master_sha = bare_repo.heads.master.commit.hexsha

		self._modify_commit_push(work_repo, "test.txt", "c3",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		assert_raises(MergeError, self.store.merge_changeset, self.repo_id, "repo", "refs/pending/1", "master")
		clone_repo = bare_repo.clone(bare_repo.working_dir + ".clone2")
		assert_equals(master_sha, clone_repo.heads.master.commit.hexsha)  # Makes sure the repository has reset

	def test_push_forwarding_fail_repo_reset(self):
		self.store.create_repository(self.repo_id, "repo")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")
		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")

		# The conflict commit goes back to the forward repo first, simulating a user pushing without Koality
		conflict_repo = Repo(self.remote_repo_path).clone(bare_repo.working_dir + ".conflict")
		self._modify_commit_push(conflict_repo, "test.txt", "a conflict")

		master_sha = bare_repo.heads.master.commit.hexsha

		self._modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		assert_raises(Exception, self.store.merge_changeset, self.repo_id, "repo", "refs/pending/1", "master")
		clone_repo = bare_repo.clone(bare_repo.working_dir + ".clone2")
		assert_equals(master_sha, clone_repo.heads.master.commit.hexsha)  # Makes sure the repository has reset

	'''
	def test_store_local_commit_as_pending(self):
		self.store.create_repository(self.repo_id, "remote_repo.git")

		bare_repo = Repo.init(self.remote_repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		self._modify_commit_push(work_repo, "test.txt", "c1")
		first_sha = bare_repo.heads.master.commit.hexsha

		self._modify_commit_push(work_repo, "test.txt", "c2")
		second_sha = bare_repo.heads.master.commit.hexsha

		self.store.store_pending(self.repo_id, "remote_repo.git", first_sha, 42)

		work_repo.git.fetch("origin", "refs/pending/42:pending")

		assert_equals(first_sha, work_repo.heads.pending.commit.hexsha)
		assert_equals(second_sha, work_repo.heads.master.commit.hexsha)
	'''

	def test_store_remote_commit_as_pending(self):
		self.store.create_repository(self.repo_id, "remote_repo")
		self.store.create_repository(self.repo_id, "repo")

		remote_repo_path = os.path.join(self.repodir, "remote_repo.git")

		remote_repo = Repo.init(remote_repo_path, bare=True)
		remote_work_repo = remote_repo.clone(remote_repo.working_dir + ".clone")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		# Push commit to remote repo
		self._modify_commit_push(remote_work_repo, "test.txt", "c1")
		master_sha = remote_repo.heads.master.commit.hexsha

		assert_items_equal([], bare_repo.heads)

		# Store commit into main repo
		self.store.store_pending(self.repo_id, "repo", master_sha, 42)

		work_repo.git.fetch("origin", "refs/pending/42:pending")

		assert_equals(master_sha, work_repo.heads.pending.commit.hexsha)

	def _create_repo_store(self):
		ins = schema.repostore.insert().values(ip_address="127.0.0.1", repositories_path="/tmp")
		with ConnectionFactory.get_sql_connection() as conn:
			result = conn.execute(ins)
			return result.inserted_primary_key[0]

	def test_get_ip_address(self):
		ip_address = self.store._get_ip_address()
		assert_not_equals(ip_address, 'localhost')

		numbers = ip_address.split('.')
		assert_equals(len(numbers), 4)

		for i in numbers:
			i = int(i)
			assert_greater_equal(i, 0)
			assert_less_equal(i, 255)
