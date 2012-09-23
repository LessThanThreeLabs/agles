import os
import unittest

from shutil import rmtree
from nose.tools import *
from verification_server import *
from settings.model_server import *
from dulwich.repo import Repo

VM_DIRECTORY = '/tmp/verification'


class VerificationTest(unittest.TestCase):
	@classmethod
	def setup_class(cls):
		vs = VerificationServer(model_server_rpc_address, VM_DIRECTORY)
		vs.vagrant.spawn()

	@classmethod
	def teardown_class(cls):
		vs = VerificationServer(model_server_rpc_address, VM_DIRECTORY)
		vs.vagrant.teardown()

	def setUp(self):
		self.vs = VerificationServer(model_server_rpc_address, VM_DIRECTORY)
		self.repo_dir = os.path.join(VM_DIRECTORY, 'repo')
		rmtree(self.repo_dir, ignore_errors=True)
		os.mkdir(self.repo_dir)

	def tearDown(self):
		rmtree(self.repo_dir)

	def test_hello_world_repo(self):
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'hello.py'), 'w') as hello:
			hello.write('print "Hello World!"')
		repo.stage(['hello.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self.vs.verify(self.repo_dir, commit_id, 'ref', lambda retval: assert_equals(0, retval))

	def test_bad_repo(self):
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'bad_file.py'), 'w') as bad_file:
			bad_file.write('def derp(herp):\n'
				'\tprint herp\n'
				'derp(1, 2)')
		repo.stage(['bad_file.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self.vs.verify(self.repo_dir, commit_id, 'ref', lambda retval: assert_equals(1, retval))
