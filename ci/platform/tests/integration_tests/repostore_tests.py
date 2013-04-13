import os
import shutil

from os.path import exists

from nose.tools import *
from git import Repo
from repo.store import FileSystemRepositoryStore, MergeError

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
		self.store.create_repository(self.repo_id, "repo.git", "privatekey")
		assert_true(exists(self.repo_path), msg="Repository does not exist.")
		assert_true(exists(self.repo_path + ".id_rsa"), msg="Repository private key file does not exist.")

	def test_repo_create_remove(self):
		self.store.create_repository(self.repo_id, "repo.git", "privatekey")
		assert_true(exists(self.repo_path), msg="Repository was not deleted.")
		self.store.delete_repository(self.repo_id, "repo.git")
		assert_false(exists(self.repo_path), msg="Repository was not deleted.")
		assert_false(exists(self.repo_path + ".id_rsa"), msg="Repository private key file was not deleted.")

	def test_merge_pass(self):
		self.store.create_repository(self.repo_id, "repo.git", "privatekey")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")

		self._modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		repo_slave = bare_repo.clone(self.repo_path + ".slave")
		self.store.merge_refs(repo_slave, "refs/pending/1", "master")

	def test_merge_fail(self):
		self.store.create_repository(self.repo_id, "repo.git", "privatekey")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")
		self._modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit])

		master_sha = bare_repo.heads.master.commit.hexsha

		self._modify_commit_push(work_repo, "test.txt", "c3",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		assert_raises(MergeError, self.store.merge_changeset, self.repo_id, "repo.git", "refs/pending/1", "master")
		clone_repo = bare_repo.clone(bare_repo.working_dir + ".clone2")
		assert_equals(master_sha, clone_repo.heads.master.commit.hexsha)  # Makes sure the repository has reset

	def test_push_forwarding_fail_repo_reset(self):
		self.store.create_repository(self.repo_id, "repo.git", "privatekey")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")

		master_sha = bare_repo.heads.master.commit.hexsha

		self._modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		assert_raises(Exception, self.store.merge_changeset, self.repo_id, "repo.git", "refs/pending/1", "master")
		clone_repo = bare_repo.clone(bare_repo.working_dir + ".clone2")
		assert_equals(master_sha, clone_repo.heads.master.commit.hexsha)  # Makes sure the repository has reset

	def test_get_ip_address(self):
		ip_address = self.store._get_ip_address()
		assert_not_equals(ip_address, 'localhost')
		assert_not_equals(ip_address, '127.0.0.1')

		numbers = ip_address.split('.')
		assert_equals(len(numbers), 4)

		for i in numbers:
			i = int(i)
			assert_greater_equal(i, 0)
			assert_less_equal(i, 255)
