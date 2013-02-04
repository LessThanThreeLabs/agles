import os

import yaml

from git import Repo
from nose.tools import *
from shutil import rmtree
from testconfig import config

from settings.verification_server import VerificationServerSettings
from util.test import BaseIntegrationTest
from util.test.fake_build_verifier import FakeBuildVerifier
from util.test.mixins import *
from virtual_machine.vagrant import Vagrant
from verification.server.build_verifier import BuildVerifier
from verification.shared.verification_result import VerificationResult

VM_DIRECTORY = '/tmp/verification'


class BuildVerifierTest(BaseIntegrationTest, ModelServerTestMixin,
	RabbitMixin, RepoStoreTestMixin):
	@classmethod
	def setup_class(cls):
		cls.use_vagrant = config.get('useVagrant')
		if cls.use_vagrant:
			vagrant = Vagrant(VM_DIRECTORY, VerificationServerSettings.local_box_name)
			cls.verifier = BuildVerifier.for_virtual_machine(vagrant)
		else:
			cls.verifier = FakeBuildVerifier(passes=True)
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
		if not self.use_vagrant:
			self.verifier.passes = True
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "koality.yml",
			yaml.dump({'test': [{'hello_world': {'script': 'echo Hello World!'}}]}),
			refspec="HEAD:refs/pending/1")

		self.verifier.verify(self.repo_dir, ["refs/pending/1"],
			lambda retval, cleanup=None: assert_equal(VerificationResult.SUCCESS, retval))

	def test_bad_repo(self):
		if not self.use_vagrant:
			self.verifier.passes = False
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "koality.yml",
			yaml.dump({'test': [{'fail': {'script': 'exit 42'}}]}),
			refspec="HEAD:refs/pending/1")

		self.verifier.verify(self.repo_dir, ["refs/pending/1"],
			lambda retval, cleanup=None: assert_equal(VerificationResult.FAILURE, retval))
