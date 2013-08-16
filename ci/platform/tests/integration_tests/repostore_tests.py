import os
import shutil

from os.path import exists

import model_server
import hglib

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
		self.git_repo_id = 1
		self.git_repo_path = os.path.join(
			self.repodir,
			to_path(self.git_repo_id, "gitrepo.git"))
		self.hg_repo_id = 2
		self.hg_repo_path = os.path.join(
			self.repodir,
			to_path(self.hg_repo_id, "hgrepo"))
		self._start_model_server()

		StoreSettings.ssh_private_key = 'NotARealPrivateKey'

		self.repostore_id = self._create_repo_store()
		self.remote_git_repo_path = os.path.join(self.repodir, "remote_git_repo.git")
		Repo.init(self.remote_git_repo_path, bare=True)

		self.remote_hg_repo_path = os.path.join(self.repodir, "hg_remote_repo")
		hglib.init(self.remote_hg_repo_path)
		os.makedirs(os.path.join(self.remote_hg_repo_path, ".hg", "strip-backup"))

		with model_server.rpc_connect("repos", "create") as model_rpc:
			model_rpc._create_repo_in_db(self.git_repo_id, "gitrepo", "git_repo_uri", self.repostore_id, self.remote_git_repo_path, 0, "git")
			model_rpc._create_repo_in_db(self.hg_repo_id, "hgrepo", "hg_repo_uri", self.repostore_id, self.remote_hg_repo_path, 0, "hg")

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

	def test_git_repo_create(self):
		assert_false(exists(self.git_repo_path), msg="Repository should not exist.")
		self.store.create_repository(self.git_repo_id, "gitrepo")
		assert_true(exists(self.git_repo_path), msg="Repository does not exist.")

	def test_hg_repo_create(self):
		assert_false(exists(self.hg_repo_path), msg="Repository should not exist.")
		self.store.create_repository(self.hg_repo_id, "hgrepo")
		assert_true(exists(self.hg_repo_path), msg="Repository does not exist.")

	def test_git_repo_create_remove(self):
		self.store.create_repository(self.git_repo_id, "gitrepo")
		assert_true(exists(self.git_repo_path), msg="Repository was not deleted.")
		self.store.delete_repository(self.git_repo_id, "gitrepo")
		assert_false(exists(self.git_repo_path), msg="Repository was not deleted.")

	def test_hg_repo_create_remove(self):
		self.store.create_repository(self.hg_repo_id, "hgrepo")
		assert_true(exists(self.hg_repo_path), msg="Repository was not deleted.")
		self.store.delete_repository(self.hg_repo_id, "hgrepo")
		assert_false(exists(self.hg_repo_path), msg="Repository was not deleted.")

	def test_git_merge_pass(self):
		self.store.create_repository(self.git_repo_id, "gitrepo")

		bare_repo = Repo.init(self.git_repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._git_modify_commit_push(work_repo, "test.txt", "c1")

		self._git_modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		repo_slave = bare_repo.clone(self.git_repo_path + ".slave")
		self.store.git_merge_refs(repo_slave, "refs/pending/1", "master")
	
	def test_hg_merge_pass(self):
		self.store.create_repository(self.hg_repo_id, "hgrepo")

		hglib.clone(source=self.remote_hg_repo_path, dest=self.hg_repo_path + ".first_clone")
		direct_repo = hglib.open(self.hg_repo_path + ".first_clone")
	
		hglib.clone(source=self.hg_repo_path, dest=self.hg_repo_path + ".second_clone")
		second_repo = hglib.open(self.hg_repo_path + ".second_clone")

		initial_sha = self._hg_modify_commit_push(direct_repo, "a.txt", "a")

		new_sha = self._hg_modify_commit(second_repo, "b.txt", "b")

		os.makedirs(os.path.join(self.hg_repo_path, ".hg", "strip-backup"))
		second_repo.bundle(os.path.join(self.hg_repo_path, ".hg", "strip-backup", "%s.hg" % new_sha), all=True)

		self.store.merge_changeset(self.hg_repo_id, "hgrepo", new_sha, new_sha)

		assert_equals(hglib.open(self.hg_repo_path).tip()[5], "Merging in %s" % new_sha[:12])

	def test_git_merge_fail(self):
		self.store.create_repository(self.git_repo_id, "gitrepo")

		bare_repo = Repo.init(self.git_repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._git_modify_commit_push(work_repo, "test.txt", "c1")
		self._git_modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit])

		master_sha = bare_repo.heads.master.commit.hexsha

		self._git_modify_commit_push(work_repo, "test.txt", "c3",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		assert_raises(MergeError, self.store.merge_changeset, self.git_repo_id, "gitrepo", "refs/pending/1", "master")
		clone_repo = bare_repo.clone(bare_repo.working_dir + ".clone2")
		assert_equals(master_sha, clone_repo.heads.master.commit.hexsha)  # Makes sure the repository has reset

	def test_hg_push_forwarding_fail_reset(self):
		self.store.create_repository(self.hg_repo_id, "hgrepo")

		hglib.clone(source=self.remote_hg_repo_path, dest=self.hg_repo_path + ".first_clone")
		direct_repo = hglib.open(self.hg_repo_path + ".first_clone")
	
		hglib.clone(source=self.hg_repo_path, dest=self.hg_repo_path + ".second_clone")
		second_repo = hglib.open(self.hg_repo_path + ".second_clone")

		initial_sha = self._hg_modify_commit_push(direct_repo, "a.txt", "a")

		new_sha = self._hg_modify_commit(second_repo, "a.txt", "b")

		os.makedirs(os.path.join(self.hg_repo_path, ".hg", "strip-backup"))
		second_repo.bundle(os.path.join(self.hg_repo_path, ".hg", "strip-backup", "%s.hg" % new_sha), all=True)

		assert_raises(MergeError, self.store.merge_changeset, self.hg_repo_id, "hgrepo", new_sha, new_sha)
		assert_equals(hglib.open(self.hg_repo_path).tip()[1], initial_sha)

	def test_git_push_forwarding_fail_repo_reset(self):
		self.store.create_repository(self.git_repo_id, "gitrepo")

		bare_repo = Repo.init(self.git_repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")
		init_commit = self._git_modify_commit_push(work_repo, "test.txt", "c1")

		# The conflict commit goes back to the forward repo first, simulating a user pushing without Koality
		conflict_repo = Repo(self.remote_git_repo_path).clone(bare_repo.working_dir + ".conflict")
		self._git_modify_commit_push(conflict_repo, "test.txt", "a conflict")

		master_sha = bare_repo.heads.master.commit.hexsha

		self._git_modify_commit_push(work_repo, "test.txt", "c2",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		assert_raises(Exception, self.store.merge_changeset, self.git_repo_id, "gitrepo", "refs/pending/1", "master")
		clone_repo = bare_repo.clone(bare_repo.working_dir + ".clone2")
		assert_equals(master_sha, clone_repo.heads.master.commit.hexsha)  # Makes sure the repository has reset

	def test_hg_push_forwarding_fail_repo_reset(self):
		self.store.create_repository(self.hg_repo_id, "hgrepo")


	def test_store_remote_commit_as_pending(self):
		self.store.create_repository(self.git_repo_id, "remote_git_repo")
		self.store.create_repository(self.git_repo_id, "gitrepo")

		remote_git_repo_path = os.path.join(self.repodir, "remote_git_repo.git")

		remote_repo = Repo(remote_git_repo_path)
		remote_work_repo = remote_repo.clone(remote_repo.working_dir + ".clone")

		bare_repo = Repo.init(self.git_repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		# Push commit to remote repo
		self._git_modify_commit_push(remote_work_repo, "test.txt", "c1")
		master_sha = remote_repo.heads.master.commit.hexsha

		assert_items_equal([], bare_repo.heads)

		# Store commit into main repo
		self.store.store_pending(self.git_repo_id, "gitrepo", master_sha, 42)

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
