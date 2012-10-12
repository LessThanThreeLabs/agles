import os

from git import Repo
from nose.tools import *
from shutil import rmtree
from testconfig import config

from settings.verification_server import box_name
from util.test import BaseIntegrationTest
from util.test.fake_build_verifier import FakeBuildVerifier
from util.test.mixins import *
from vagrant.vagrant_wrapper import VagrantWrapper
from verification.server.build_verifier import BuildVerifier
from verification.server.verification_result import VerificationResult

VM_DIRECTORY = '/tmp/verification'


class BuildVerifierTest(BaseIntegrationTest, ModelServerTestMixin,
	RabbitMixin, RepoStoreTestMixin):
	@classmethod
	def setup_class(cls):
		if config.get("fakeverifier"):
			cls.verifier = FakeBuildVerifier(passes=True)
		else:
			vagrant_wrapper = VagrantWrapper.vm(VM_DIRECTORY, box_name)
			cls.verifier = BuildVerifier(vagrant_wrapper)
		cls.verifier.setup()

	@classmethod
	def teardown_class(cls):
		rmtree(VM_DIRECTORY, ignore_errors=True)
		cls.verifier.teardown()

	def setUp(self):
		self._purge_queues()
		self.repo_dir = os.path.join(VM_DIRECTORY, "repo.git")
		self.work_repo_dir = self.repo_dir + ".clone"
		rmtree(self.repo_dir, ignore_errors=True)
		rmtree(self.work_repo_dir, ignore_errors=True)
		os.makedirs(self.repo_dir)
		os.makedirs(self.work_repo_dir)
		self._start_model_server()

	def tearDown(self):
		rmtree(self.repo_dir)
		rmtree(self.work_repo_dir)
		self._stop_model_server()
		self._purge_queues()

	def test_hello_world_repo(self):
		if config.get("fakeverifier"):
			self.verifier = FakeBuildVerifier(passes=True)
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "hello.py", "print 'Hello World!'",
			refspec="HEAD:refs/pending/1")

		self.verifier.verify(self.repo_dir, ["refs/pending/1"],
			lambda retval: assert_equals(VerificationResult.SUCCESS, retval))

	def test_bad_repo(self):
		if config.get("fakeverifier"):
			self.verifier = FakeBuildVerifier(passes=False)
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "hello.py", "4 = 'x' + 2",
			refspec="HEAD:refs/pending/1")

		self.verifier.verify(self.repo_dir, ["refs/pending/1"],
			lambda retval: assert_equals(VerificationResult.FAILURE, retval))
