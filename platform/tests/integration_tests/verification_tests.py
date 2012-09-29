import os
import time

from kombu import Connection
from shutil import rmtree
from nose.tools import *
from util.vagrant import Vagrant
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin
from multiprocessing import Process
from database.engine import EngineFactory
from database import schema
from verification.master import *
from verification.server import *
from verification.server.verification_request_handler import VerificationRequestHandler
from verification.server.verification_result import VerificationResult
from settings.model_server import *
from settings.rabbit import *
from settings.verification_server import *
from dulwich.repo import Repo

VM_DIRECTORY = '/tmp/verification'


class VerificationRequestHandlerTest(BaseIntegrationTest, ModelServerTestMixin):
	@classmethod
	def setup_class(cls):
		cls.vagrant = Vagrant(VM_DIRECTORY, box_name)
		cls.handler = VerificationRequestHandler(cls.vagrant)
		cls.vagrant.spawn()

	@classmethod
	def teardown_class(cls):
		cls.vagrant.teardown()

	def setUp(self):
		self.repo_dir = os.path.join(VM_DIRECTORY, 'repo')
		rmtree(self.repo_dir, ignore_errors=True)
		os.mkdir(self.repo_dir)
		self._start_model_server()

	def tearDown(self):
		rmtree(self.repo_dir)
		self._stop_model_server()

	def test_hello_world_repo(self):
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'hello.py'), 'w') as hello:
			hello.write('print "Hello World!"')
		repo.stage(['hello.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self.handler.verify(self.repo_dir, [(commit_id, 'ref',)],
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

		self.handler.verify(self.repo_dir, [(commit_id, 'ref',)],
			lambda retval: assert_equals(VerificationResult.FAILURE, retval))


class VerificationMasterTest(BaseIntegrationTest, ModelServerTestMixin):
	@classmethod
	def setup_class(cls):
			vagrant = Vagrant(VM_DIRECTORY, box_name)
			verification_server = VerificationServer(vagrant)
			cls.vs_process = Process(target=verification_server.run)
			verification_master = VerificationMaster()
			cls.vm_process = Process(target=verification_master.run)
			cls.vs_process.start()
			cls.vm_process.start()

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
			ins_map = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_key)
			conn.execute(ins_map)

	def _on_response(self, body, message):
		self.response = body
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def test_hello_world_repo(self):
		repo = Repo.init(self.repo_dir)

		with open(os.path.join(self.repo_dir, 'hello.py'), 'w') as hello:
			hello.write('print "Hello World!"')
		repo.stage(['hello.py'])
		commit_id = repo.do_commit('First commit',
				committer='Brian Bland <r4nd0m1n4t0r@gmail.com>')

		self._insert_repo_info(self.repo_dir)

		with Connection('amqp://guest:guest@localhost//') as connection:
			with connection.Producer(serializer="msgpack") as producer:
				producer.publish(("hash", commit_id, "ref"),
					exchange=repo_update_queue.exchange,
					routing_key=repo_update_queue.routing_key,
					delivery_mode=1
				)
			with connection.Consumer(merge_queue, callbacks=[self._on_response]) as consumer:
				consumer.consume()
				self.response = None
				start_time = time.time()
				while self.response is None:
					connection.drain_events()
					assert time.time() - start_time < 90  # 90s timeout

		assert_equals(("hash", commit_id, "ref"), self.response)
