import os
import socket
import time
import binascii

import yaml

from hashlib import sha512
from kombu.connection import Connection
from kombu.entity import Queue
from shutil import rmtree
from nose.tools import *
from util.test import BaseIntegrationTest
from util.test.mixins import *
from database.engine import ConnectionFactory
from database import schema
from model_server.events_broker import EventsBroker
from verification.verification_server import VerificationServer
from settings.rabbit import RabbitSettings
from shared.constants import BuildStatus
from repo.store import FileSystemRepositoryStore, RepositoryStore
from util.pathgen import to_path
from settings.store import StoreSettings
from bunnyrpc.server import Server
from bunnyrpc.client import Client
from git import Repo
from util.test.fake_build_verifier import FakeBuildVerifier
from verification.verifier_pool import VerifierPool

DEFAULT_NUM_VERIFIERS = 10
TEST_ROOT = "/tmp/verification"


class VerificationRoundTripTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin, RepoStoreTestMixin, RedisTestMixin):

	class FakeBuildVerifierPool(VerifierPool):
		def spawn_verifier(self, verifier_number):
			return FakeBuildVerifier(passes=True)

	@classmethod
	def setup_class(cls):
		cls.repostore_id = 1
		cls.repo_dir = os.path.join(TEST_ROOT, 'repo')
		repo_store = Server(FileSystemRepositoryStore(cls.repo_dir))
		repo_store.bind(StoreSettings.rpc_exchange_name, [RepositoryStore.queue_name(cls.repostore_id)], auto_delete=True)

		cls.repo_store_process = TestProcess(target=repo_store.run)
		cls.repo_store_process.start()

	@classmethod
	def teardown_class(cls):
		cls.repo_store_process.terminate()
		cls.repo_store_process.join()
		rmtree(TEST_ROOT, ignore_errors=True)

	def setUp(self):
		super(VerificationRoundTripTest, self).setUp()
		self._purge_queues()
		self.repo_id = 1
		rmtree(self.repo_dir, ignore_errors=True)
		os.makedirs(self.repo_dir)
		self._start_model_server()
		self.verifier_pool = VerificationRoundTripTest.FakeBuildVerifierPool(DEFAULT_NUM_VERIFIERS)
		self.repo_path = os.path.join(
			self.repo_dir,
			to_path(self.repo_id, "repo.git"))
		self.forward_repo_url = os.path.join(self.repo_dir, "forwardrepo.git")
		Repo.init(self.forward_repo_url, bare=True)
		self._start_redis()
		verification_server = VerificationServer(self.verifier_pool)
		self.vs_process = TestProcess(target=verification_server.run)
		self.vs_process.start()

		with ConnectionFactory.get_sql_connection() as conn:
			ins_user = schema.user.insert().values(email="bbland@lt3.com", first_name="brian", last_name="bland", password_hash=binascii.b2a_base64(sha512("").digest())[0:-1], salt="1234567890123456", created=0)
			self.user_id = conn.execute(ins_user).inserted_primary_key[0]

	def tearDown(self):
		super(VerificationRoundTripTest, self).setUp()
		rmtree(self.repo_dir)
		self._stop_model_server()
		self.vs_process.terminate()
		self.vs_process.join()
		self.verifier_pool.teardown()
		self._stop_redis()
		self._purge_queues()

	def _insert_repo_info(self, repo_uri):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_machine = schema.repostore.insert().values(ip_address="127.0.0.1", repositories_path=self.repo_dir)
			repostore_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(id=self.repo_id, name="repo.git", repostore_id=repostore_key, uri=repo_uri,
				forward_url=self.forward_repo_url, privatekey="privatekey", publickey="publickey", created=120929)
			repo_key = conn.execute(ins_repo).inserted_primary_key[0]
			return repo_key

	def _insert_commit_info(self):
		commit_id = 0
		with ConnectionFactory.get_sql_connection() as conn:
			ins_commit = schema.commit.insert().values(id=commit_id, repo_id=self.repo_id,
				user_id=self.user_id, message="commit message", sha="sha", timestamp=int(time.time()))
			conn.execute(ins_commit)
			ins_change = schema.change.insert().values(id=commit_id, commit_id=commit_id, repo_id=self.repo_id, merge_target="master",
				number=1, status=BuildStatus.QUEUED)
			conn.execute(ins_change)
			return commit_id

	def _on_response(self, body, message):
		message.channel.basic_ack(delivery_tag=message.delivery_tag)
		if body["type"] == "change finished":
			self.change_status = body["contents"]["status"]

	def _test_commands(self):
		return [{'hello_%s' % x: {'script': 'echo %s' % x}} for x in range(30)]

	def _repo_roundtrip(self, modfile, contents):
		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(self.repostore_id)) as client:
			client.create_repository(self.repo_id, "repo.git", "privatekey")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._modify_commit_push(work_repo, modfile, contents)

		repo_id = self._insert_repo_info(self.repo_path)
		commit_id = self._insert_commit_info()

		commit_sha = self._modify_commit_push(work_repo, "koality.yml",
			yaml.safe_dump({'test': self._test_commands()}),
			parent_commits=[init_commit], refspec="HEAD:refs/pending/%d" % commit_id).hexsha

		with Connection(RabbitSettings.kombu_connection_info) as connection:
			Queue("verification:repos.update", EventsBroker.events_exchange, routing_key="repos", durable=False)(connection).declare()
			events_broker = EventsBroker(connection)
			events_broker.publish("repos", repo_id, "change added",
				change_id=commit_id, merge_target="master")
			with events_broker.subscribe("repos", callback=self._on_response) as consumer:
				self.change_status = None
				start_time = time.time()
				consumer.consume()
				while self.change_status is None:
					try:
						connection.drain_events(timeout=1)
					except socket.timeout:
						pass
					assert time.time() - start_time < 120  # 120s timeout
		work_repo.git.pull()
		return commit_sha, work_repo

	def test_hello_world_repo_roundtrip(self):
		commit_sha, work_repo = self._repo_roundtrip("test.txt", "c1")
		assert_equal(BuildStatus.PASSED, self.change_status)
		assert_equal(commit_sha, work_repo.head.commit.hexsha)

	def test_roundtrip_with_postmerge_success(self):
		forward_repo = Repo(self.forward_repo_url)
		work_repo = forward_repo.clone(forward_repo.working_dir + ".clone")

		self._modify_commit_push(work_repo, "other.txt", "c2")
		commit_sha, work_repo = self._repo_roundtrip("test.txt", "c1")
		assert_equal(BuildStatus.PASSED, self.change_status)
		assert_not_equal(commit_sha, work_repo.head.commit.hexsha)

	def test_roundtrip_with_postmerge_failure(self):
		forward_repo = Repo(self.forward_repo_url)
		work_repo = forward_repo.clone(forward_repo.working_dir + ".clone")

		self._modify_commit_push(work_repo, "conflict.txt", "c2")
		self._repo_roundtrip("conflict.txt", "conflict")
		assert_equal(BuildStatus.FAILED, self.change_status)
