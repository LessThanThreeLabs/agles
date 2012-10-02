import os
import time

from kombu import Connection
from shutil import rmtree
from nose.tools import *
from util.vagrant import Vagrant
from util.test import BaseIntegrationTest
from util.test.mixins import *
from multiprocessing import Process
from database.engine import ConnectionFactory
from database import schema
from verification.master import *
from verification.server import *
from verification.server.verification_request_handler import VerificationRequestHandler
from verification.server.verification_result import VerificationResult
from settings.model_server import *
from settings.rabbit import *
from settings.verification_server import *
from repo.store import FileSystemRepositoryStore
from util.repositories import to_path
from settings import store
from bunnyrpc.server import Server
from bunnyrpc.client import Client
from git import Repo

VM_DIRECTORY = '/tmp/verification'


class VerificationRequestHandlerTest(BaseIntegrationTest, ModelServerTestMixin, RepoStoreTestMixin):
	@classmethod
	def setup_class(cls):
		cls.vagrant = Vagrant(VM_DIRECTORY, box_name)
		cls.handler = VerificationRequestHandler(cls.vagrant)
		cls.vagrant.spawn()

	@classmethod
	def teardown_class(cls):
		cls.vagrant.teardown()

	def setUp(self):
		self.repo_dir = os.path.join(VM_DIRECTORY, "repo")
		self.work_repo_dir = self.repo_dir + ".clone"
		rmtree(self.repo_dir, ignore_errors=True)
		rmtree(self.work_repo_dir, ignore_errors=True)
		os.mkdir(self.repo_dir)
		os.mkdir(self.work_repo_dir)
		self._start_model_server()

	def tearDown(self):
		rmtree(self.repo_dir)
		rmtree(self.work_repo_dir)
		self._stop_model_server()

	def test_hello_world_repo(self):
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "hello.py", "print 'Hello World!'",
			refspec="HEAD:refs/pending/1")

		self.handler.verify(self.repo_dir, [("refs/pending/1", "ref",)],
			lambda retval: assert_equals(VerificationResult.SUCCESS, retval))

	def test_bad_repo(self):
		repo = Repo.init(self.repo_dir, bare=True)
		work_repo = repo.clone(self.work_repo_dir)
		self._modify_commit_push(work_repo, "hello.py", "4 = 'x' + 2",
			refspec="HEAD:refs/pending/1")

		self.handler.verify(self.repo_dir, [("refs/pending/1", "ref",)],
			lambda retval: assert_equals(VerificationResult.FAILURE, retval))


class VerificationMasterTest(BaseIntegrationTest, ModelServerTestMixin, RepoStoreTestMixin):
	@classmethod
	def setup_class(cls):
			vagrant = Vagrant(VM_DIRECTORY, box_name)
			verification_server = VerificationServer(vagrant)
			cls.vs_process = Process(target=verification_server.run)
			verification_master = VerificationMaster()
			cls.vm_process = Process(target=verification_master.run)
			cls.repo_dir = os.path.join(VM_DIRECTORY, 'repo')
			repo_store = Server(FileSystemRepositoryStore(cls.repo_dir))
			repo_store.bind(store.rpc_exchange_name, ["fs0"])
			cls.repo_store_process = Process(target=repo_store.run)
			cls.vs_process.start()
			cls.vm_process.start()
			cls.repo_store_process.start()

	@classmethod
	def teardown_class(cls):
		cls.vs_process.terminate()
		cls.vm_process.terminate()
		cls.repo_store_process.terminate()

	def setUp(self):
		super(VerificationMasterTest, self).setUp()
		rmtree(self.repo_dir, ignore_errors=True)
		os.mkdir(self.repo_dir)
		self._start_model_server()
		self.repo_path = os.path.join(
			self.repo_dir,
			to_path("asdf", "repo", FileSystemRepositoryStore.DIR_LEVELS))

	def tearDown(self):
		super(VerificationMasterTest, self).setUp()
		rmtree(self.repo_dir)
		self._stop_model_server()

	def _insert_repo_info(self, repo_uri):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_machine = schema.machine.insert().values(uri="fs0")
			machine_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(name="repo", hash="asdf", machine_id=machine_key)
			repo_key = conn.execute(ins_repo).inserted_primary_key[0]
			ins_map = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_key)
			conn.execute(ins_map)

	def _on_response(self, body, message):
		self.response = body
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def test_hello_world_repo_roundtrip(self):
		with Client(store.rpc_exchange_name, "fs0") as client:
			client.create_repository("asdf", "repo")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")
		self._modify_commit_push(work_repo, "hello.py", "print 'Hello World!'",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/1")

		self._insert_repo_info(self.repo_path)

		with Connection('amqp://guest:guest@localhost//') as connection:
			with connection.Producer(serializer="msgpack") as producer:
				producer.publish(("asdf", "refs/pending/1", "master"),
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

		assert_equals(("asdf", "refs/pending/1", "master"), self.response)
