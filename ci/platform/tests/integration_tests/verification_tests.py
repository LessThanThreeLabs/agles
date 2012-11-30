import os

import yaml

from git import Repo
from nose.tools import *
from shutil import rmtree
from testconfig import config

from settings.verification_server import box_name
from util.test import BaseIntegrationTest
from util.test.fake_build_verifier import FakeBuildVerifier, FakeUriTranslator
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
			cls.verifier = BuildVerifier(vagrant_wrapper, FakeUriTranslator())
		cls.verifier.setup()

	@classmethod
	def teardown_class(cls):
		cls.verifier.teardown()
		rmtree(VM_DIRECTORY, ignore_errors=True)

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
		self._modify_commit_push(work_repo, "agles_config.yml",
			yaml.dump({'test': [{'hello_world': {'script': 'echo Hello World!'}}]}),
			refspec="HEAD:refs/pending/1")

		self.verifier.verify(self.repo_dir, ["refs/pending/1"],
			lambda retval, cleanup=None: assert_equals(VerificationResult.SUCCESS, retval))

	def test_bad_repo(self):
		if config.get("fakeverifier"):
			self.verifier = FakeBuildVerifier(passes=False)
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "agles_config.yml",
			yaml.dump({'test': [{'fail': {'script': 'exit 42'}}]}),
			refspec="HEAD:refs/pending/1")

		self.verifier.verify(self.repo_dir, ["refs/pending/1"],
			lambda retval, cleanup=None: assert_equals(VerificationResult.FAILURE, retval))
