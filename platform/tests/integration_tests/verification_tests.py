import os
import time
import unittest

from shutil import rmtree
from nose.tools import *
from util.vagrant import Vagrant
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin
from multiprocessing import Process
from verification_master import *
from verification_server import *
from verification_server.verification_result import VerificationResult
from settings.model_server import *
from settings.verification_server import *
from dulwich.repo import Repo

VM_DIRECTORY = '/tmp/verification'


class VerificationServerTest(unittest.TestCase):
	@classmethod
	def setup_class(cls):
		vagrant = Vagrant(VM_DIRECTORY, box_name)
		cls.verification_server = VerificationServer(vagrant)
		cls.verification_server.vagrant.spawn()

	@classmethod
	def teardown_class(cls):
		cls.verification_server.vagrant.teardown()

	def setUp(self):
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

		self.verification_server.verify(self.repo_dir, [(commit_id, 'ref',)],
			lambda retval: assert_equals(VerificationResult.SUCCESS, retval))

	def test_bad_repo(self):
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'bad_file.py'), 'w') as bad_file:
			bad_file.write('def derp(herp):\n'
				'\tprint herp\n'
				'derp(1, 2)')
		repo.stage(['bad_file.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self.verification_server.verify(self.repo_dir, [(commit_id, 'ref',)],
			lambda retval: assert_equals(VerificationResult.FAILURE, retval))

"""
class VerificationMasterTest(BaseIntegrationTest, ModelServerTestMixin):
	@classmethod
	def setup_class(cls):
			vs = VerificationServer(VM_DIRECTORY)
			cls.vs_process = Process(target=vs.run)
			vm = VerificationMaster()
			cls.vm_process = Process(target=vm.run)
			cls.vs_process.run()
			cls.vm_process.run()

	@classmethod
	def teardown_class(cls):
		cls.vs_process.terminate()
		cls.vm_process.terminate()

	def setUp(self):
		super(VerificationMasterTest, self).setUp()
		self.repo_dir = os.path.join(VM_DIRECTORY, 'repo')
		rmtree(self.repo_dir, ignore_errors=True)
		os.mkdir(self.repo_dir)
		self._start_model_server()

	def tearDown(self):
		super(VerificationMasterTest, self).setUp()
		rmtree(self.repo_dir)
		self._stop_model_server()

	def _insert_repo_info(self, repo_uri):
		with EngineFactory.get_connection() as conn:
			ins_machine = schema.machine.insert().values(uri="localhost")
			machine_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(name="repo", hash="hash", machine_id=machine_key)
			repo_key = conn.execute(ins_repo).inserted_primary_key[0]
			ins_map = schema.repo.insert().values(uri=repo_uri, repo_id=repo_key)
			conn.execute(ins_map)

	def _on_response(self, channel, method, properties, body):
		self.response = msgpack.unpackb(body)

	def test_hello_world_repo(self):
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'hello.py'), 'w') as hello:
			hello.write('print "Hello World!"')
		repo.stage(['hello.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self._insert_repo_info(self.repo_dir)

		rabbit_connection = pika.BlockingConnectionn(connection_parameters)

		output_channel = rabbit_connection.channel()
		output_channel.queue_declare(queue=repo_update_routing_key, durable=True)

		input_channel = rabbit_connection.channel()
		input_channel.queue_declare(queue=merge_queue_name, durable=True)

		output_channel.basic_publish(exchange='',
			routing_key=repo_update_routing_key,
			body=msgpack.packb(("hash", commit_id, "ref",)),
			properties=pika.BasicProperties(
				delivery_mode=1,
			))

		self.response = None
		start_time = time.time()
		input_channel.basic_consume(self._on_response, queue=merge_queue_name)
		while self.response is None:
			rabbit_connection.process_data_events()
			assert time.time() - start_time < 60000  # 1 minute timeout

		assert_equals(("hash", commit_id, "ref"), self.response)
"""
