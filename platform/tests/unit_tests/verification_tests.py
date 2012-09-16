import os

from shutil import rmtree
from nose.tools import unittest
from nose.tools import *
from verification_server import *
from settings.model_server import *
from dulwich.repo import Repo

VM_DIRECTORY = '/tmp/verification'


class VerificationTest(unittest.TestCase):
	def setUp(self):
		self.vs = VerificationServer(model_server_rpc_address, VM_DIRECTORY)
		self.vs.vagrant.spawn()
		self.repo_dir = os.path.join(VM_DIRECTORY, 'repo')

	def tearDown(self):
		rmtree(self.repo_dir)
		self.vs.vagrant.teardown()

	def test_hello_world_repo(self):
		os.mkdir(self.repo_dir)
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'hello.py'), 'w') as hello:
			hello.write('print "Hello World!"')
		repo.stage(['hello.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self.vs.verify('/vagrant/repo', commit_id, 'ref', lambda retval: assert_equals(0, retval))

	def test_bad_repo(self):
		os.mkdir(self.repo_dir)
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'derp.py'), 'w') as derp:
			derp.write('def derp(herp):\n'
				'\tprint herp\n'
				'derp(1, 2)')
		repo.stage(['derp.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self.vs.verify('/vagrant/repo', commit_id, 'ref', lambda retval: assert_equals(1, retval))
