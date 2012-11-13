import os
import time

from hashlib import sha512
from kombu.connection import Connection
from shutil import rmtree
from nose.tools import *
from util.permissions import RepositoryPermissions
from vagrant.vagrant_wrapper import VagrantWrapper
from util.test import BaseIntegrationTest
from util.test.mixins import *
from model_server.events_broker import EventsBroker
from database.engine import ConnectionFactory
from database import schema
from verification.master import *
from verification.server import *
from verification.server.build_verifier import BuildVerifier
from settings.rabbit import connection_info
from settings.verification_server import *
from repo.store import FileSystemRepositoryStore
from util.pathgen import to_path
from settings import store
from bunnyrpc.server import Server
from bunnyrpc.client import Client
from git import Repo
from testconfig import config
from util.test.fake_build_verifier import FakeBuildVerifier, FakeUriTranslator

VM_DIRECTORY = '/tmp/verification'


class VerificationRoundTripTest(BaseIntegrationTest, ModelServerTestMixin,
	RabbitMixin, RepoStoreTestMixin, RedisTestMixin):
	@classmethod
	def setup_class(cls):
		if config.get("fakeverifier"):
			cls.verifier = FakeBuildVerifier(passes=True)
		else:
			vagrant_wrapper = VagrantWrapper.vm(VM_DIRECTORY, box_name)
			cls.verifier = BuildVerifier(vagrant_wrapper, FakeUriTranslator())
		cls.verifier.setup()
		verification_server = VerificationServer(cls.verifier)
		cls.vs_process = TestProcess(target=verification_server.run)
		cls.vs_process.start()

	@classmethod
	def teardown_class(cls):
		cls.verifier.teardown()
		cls.vs_process.terminate()
		cls.vs_process.join()
		rmtree(VM_DIRECTORY, ignore_errors=True)

	def setUp(self):
		super(VerificationRoundTripTest, self).setUp()
		self._purge_queues()
		self.repo_dir = os.path.join(VM_DIRECTORY, 'repo')
		self.repo_hash = "asdfghjkl"
		self.repo_machine = "fs0"
		rmtree(self.repo_dir, ignore_errors=True)
		os.makedirs(self.repo_dir)
		self._start_model_server()
		self.repo_path = os.path.join(
			self.repo_dir,
			to_path(self.repo_hash, "repo.git"))
		self._start_redis()
		repo_store = Server(FileSystemRepositoryStore(self.repo_dir))
		repo_store.bind(store.rpc_exchange_name, [self.repo_machine])
		self.repo_store_process = TestProcess(target=repo_store.run)
		self.repo_store_process.start()
		verification_master = VerificationMaster()
		self.vm_process = TestProcess(target=verification_master.run)
		self.vm_process.start()

	def tearDown(self):
		super(VerificationRoundTripTest, self).setUp()
		rmtree(self.repo_dir)
		self._stop_model_server()
		self.vm_process.terminate()
		self.vm_process.join()
		self.repo_store_process.terminate()
		self.repo_store_process.join()
		self._stop_redis()
		self._purge_queues()

	def _insert_repo_info(self, repo_uri):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_machine = schema.machine.insert().values(uri=self.repo_machine, host_name="localhost", repositories_path=self.repo_dir)
			machine_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(name="repo.git", hash=self.repo_hash, machine_id=machine_key, default_permissions=RepositoryPermissions.RW)
			repo_key = conn.execute(ins_repo).inserted_primary_key[0]
			ins_map = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_key)
			conn.execute(ins_map)
			return repo_key

	def _insert_commit_info(self):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_user = schema.user.insert().values(email="bbland@lt3.com", name="brian", password_hash=sha512("").digest(), salt="1234567890123456")
			user_id = conn.execute(ins_user).inserted_primary_key[0]
			ins_commit = schema.commit.insert().values(repo_hash=self.repo_hash, user_id=user_id,
				message="commit message", timestamp=int(time.time()))
			commit_id = conn.execute(ins_commit).inserted_primary_key[0]
			return commit_id

	def _on_response(self, body, message):
		self.response = body
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def test_hello_world_repo_roundtrip(self):
		with Client(store.rpc_exchange_name, self.repo_machine) as client:
			client.create_repository(self.repo_hash, "repo.git")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")

		self._insert_repo_info(self.repo_path)
		commit_id = self._insert_commit_info()

		commit_sha = self._modify_commit_push(work_repo, "hello.py", "print 'Hello World!'",
			parent_commits=[init_commit], refspec="HEAD:refs/pending/%d" % commit_id).hexsha

		with Connection(connection_info) as connection:
			events_broker = EventsBroker(connection)
			events_broker.publish(events_broker.get_event("repos", "update"), (commit_id, "master"))
			with connection.Consumer(merge_queue, callbacks=[self._on_response]) as consumer:
				consumer.consume()
				self.response = None
				start_time = time.time()
				while self.response is None:
					connection.drain_events()
					assert time.time() - start_time < 90  # 90s timeout
		work_repo.git.pull()
		assert_equals(commit_sha, work_repo.head.commit.hexsha)
