import os
import socket
import time

import yaml

from hashlib import sha512
from kombu.connection import Connection
from shutil import rmtree
from nose.tools import *
from util.permissions import RepositoryPermissions
from virtual_machine.vagrant import Vagrant
from util.test import BaseIntegrationTest
from util.test.mixins import *
from database.engine import ConnectionFactory
from database import schema
from model_server.events_broker import EventsBroker
from verification.master import *
from verification.server import *
from verification.server.build_verifier import BuildVerifier
from settings.rabbit import connection_info
from settings.verification_server import *
from shared.constants import BuildStatus
from repo.store import FileSystemRepositoryStore, RepositoryStore
from util.pathgen import to_path
from settings import store
from bunnyrpc.server import Server
from bunnyrpc.client import Client
from git import Repo
from testconfig import config
from util.test.fake_build_verifier import FakeBuildVerifier

TEST_ROOT = '/tmp/verification'
DEFAULT_NUM_VERIFIERS = 2


class VerificationRoundTripTest(BaseIntegrationTest, ModelServerTestMixin,
	RabbitMixin, RepoStoreTestMixin, RedisTestMixin):
	@classmethod
	def setup_class(cls):
		cls.verifiers = []
		cls.vs_processes = []
		num_verifiers = int(config["numVerifiers"]) if config.get("numVerifiers") else DEFAULT_NUM_VERIFIERS
		for x in range(num_verifiers):
			if config.get("fakeVerifier"):
				verifier = FakeBuildVerifier(passes=True)
			else:
				vagrant = Vagrant(os.path.join(TEST_ROOT, str(x)), box_name)
				verifier = BuildVerifier.for_virtual_machine(vagrant)
			verifier.setup()
			cls.verifiers.append(verifier)

	@classmethod
	def teardown_class(cls):
		[verifier.teardown() for verifier in cls.verifiers]
		rmtree(TEST_ROOT, ignore_errors=True)

	def setUp(self):
		super(VerificationRoundTripTest, self).setUp()
		self._purge_queues()
		self.repo_dir = os.path.join(TEST_ROOT, 'repo')
		self.repo_id = 1
		rmtree(self.repo_dir, ignore_errors=True)
		os.makedirs(self.repo_dir)
		self._start_model_server()
		self.repo_path = os.path.join(
			self.repo_dir,
			to_path(self.repo_id, "repo.git"))
		self.forward_url = "forwardurl"
		self._start_redis()
		self.vs_processes = []
		for verifier in self.verifiers:
			verification_server = VerificationServer(verifier)
			vs_process = TestProcess(target=verification_server.run)
			vs_process.start()
			self.vs_processes.append(vs_process)

		repo_store = Server(FileSystemRepositoryStore(self.repo_dir))
		self.repostore_id = 1
		repo_store.bind(store.rpc_exchange_name, [RepositoryStore.queue_name(self.repostore_id)], auto_delete=True)

		self.repo_store_process = TestProcess(target=repo_store.run)
		self.repo_store_process.start()
		verification_master = VerificationMaster()
		self.vm_process = TestProcess(target=verification_master.run)
		self.vm_process.start()
		with ConnectionFactory.get_sql_connection() as conn:
			ins_user = schema.user.insert().values(email="bbland@lt3.com", first_name="brian", last_name="bland", password_hash=sha512("").hexdigest(), salt="1234567890123456")
			self.user_id = conn.execute(ins_user).inserted_primary_key[0]

	def tearDown(self):
		super(VerificationRoundTripTest, self).setUp()
		rmtree(self.repo_dir)
		self._stop_model_server()
		self.vm_process.terminate()
		self.vm_process.join()
		[(vs_process.terminate(), vs_process.join()) for vs_process in self.vs_processes]
		self.repo_store_process.terminate()
		self.repo_store_process.join()
		self._stop_redis()
		self._purge_queues()

	def _insert_repo_info(self, repo_uri):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_machine = schema.repostore.insert().values(host_name="localhost", repositories_path=self.repo_dir)
			repostore_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(id=self.repo_id, name="repo.git", owner=self.user_id, repostore_id=repostore_key, uri=repo_uri,
					default_permissions=RepositoryPermissions.RW, forward_url="forwardurl")
			repo_key = conn.execute(ins_repo).inserted_primary_key[0]
			return repo_key

	def _insert_commit_info(self):
		commit_id = 0
		with ConnectionFactory.get_sql_connection() as conn:
			ins_commit = schema.commit.insert().values(id=commit_id, repo_id=self.repo_id,
				user_id=self.user_id, message="commit message", timestamp=int(time.time()))
			conn.execute(ins_commit)
			ins_change = schema.change.insert().values(id=commit_id, commit_id=commit_id, repo_id=self.repo_id, merge_target="master",
				number=1, status=BuildStatus.QUEUED)
			conn.execute(ins_change)
			return commit_id

	def _on_response(self, body, message):
		if body["type"] == "change finished":
			self.change_status = body["contents"]["status"]
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def _test_commands(self):
		return [{'hello_%s' % x: {'script': 'echo %s' % x}} for x in range(30)]

	def test_hello_world_repo_roundtrip(self):
		with Client(store.rpc_exchange_name, RepositoryStore.queue_name(self.repostore_id)) as client:
			client.create_repository(self.repo_id, "repo.git")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, "test.txt", "c1")

		repo_id = self._insert_repo_info(self.repo_path)
		commit_id = self._insert_commit_info()

		commit_sha = self._modify_commit_push(work_repo, "koality.yml",
			yaml.dump({'test': self._test_commands()}),
			parent_commits=[init_commit], refspec="HEAD:refs/pending/%d" % commit_id).hexsha

		with Connection(connection_info) as connection:
			events_broker = EventsBroker(connection)
			events_broker.publish("repos", repo_id, "change added",
				change_id=commit_id, merge_target="master")
			with events_broker.subscribe("changes", callback=self._on_response) as consumer:
				self.change_status = None
				start_time = time.time()
				consumer.consume()
				while self.change_status is None:
					try:
						connection.drain_events(timeout=1)
					except socket.timeout:
						pass
					assert time.time() - start_time < 120  # 120s timeout
		assert_equals(BuildStatus.PASSED, self.change_status)
		work_repo.git.pull()
		assert_equals(commit_sha, work_repo.head.commit.hexsha)
