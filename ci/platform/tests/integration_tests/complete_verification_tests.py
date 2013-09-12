import os
import socket
import time
import binascii

import eventlet
import model_server
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
from settings.deployment import DeploymentSettings
from settings.rabbit import RabbitSettings
from sqlalchemy import func
from shared.constants import BuildStatus, MergeStatus
from repo.store import FileSystemRepositoryStore, RepositoryStore
from util.pathgen import to_path
from settings.store import StoreSettings
from bunnyrpc.server import Server
from bunnyrpc.client import Client
from git import Repo
from util.test.fake_build_verifier import FakeBuildCore
from verification.build_verifier import BuildVerifier
from verification.change_verifier import ChangeVerifier
from verification.verifier_pool import VerifierPool

DEFAULT_NUM_VERIFIERS = 2
TEST_ROOT = "/tmp/verification"


class VerificationRoundTripTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin, RepoStoreTestMixin, RedisTestMixin):

	class FakeBuildVerifierPool(VerifierPool):
		def spawn_verifier(self, verifier_number):
			return BuildVerifier(FakeBuildCore(verifier_number))

	class TestChangeVerifier(ChangeVerifier):
		def __init__(self, verifier_pool):
			super(VerificationRoundTripTest.TestChangeVerifier, self).__init__(verifier_pool, None)
			self._change_finished = eventlet.event.Event()

		def verify_change(self, verification_config, change_id, repo_type, workers_spawned, verify_only, patch_id=None):
			try:
				super(VerificationRoundTripTest.TestChangeVerifier, self).verify_change(verification_config, change_id, repo_type, workers_spawned, False, patch_id)
			finally:
				self._change_finished.send()

		def skip_change(self, change_id):
			try:
				super(VerificationRoundTripTest.TestChangeVerifier, self).skip_change(change_id)
			finally:
				self._change_finished.send()

	@classmethod
	def setup_class(cls):
		super(VerificationRoundTripTest, cls).setup_class()
		cls._purge_queues()
		cls._start_model_server()
		cls.repostore_id = 1
		cls.repo_dir = os.path.join(TEST_ROOT, 'repo')
		repo_store = Server(FileSystemRepositoryStore(cls.repostore_id, cls.repo_dir))
		repo_store.bind(StoreSettings.rpc_exchange_name, [RepositoryStore.queue_name(cls.repostore_id)], auto_delete=True)
		cls.repo_store_process = GreenProcess(target=repo_store.run)
		cls.repo_store_process.start()

	@classmethod
	def teardown_class(cls):
		cls._stop_model_server()
		cls.repo_store_process.terminate()
		cls.repo_store_process.join()
		rmtree(TEST_ROOT, ignore_errors=True)

	def setUp(self):
		super(VerificationRoundTripTest, self).setUp()
		self.repo_id = 1
		rmtree(self.repo_dir, ignore_errors=True)
		os.makedirs(self.repo_dir)
		self._start_redis()
		self.verifier_pool = VerificationRoundTripTest.FakeBuildVerifierPool(DEFAULT_NUM_VERIFIERS)
		self.repo_path = os.path.join(
			self.repo_dir,
			to_path(self.repo_id, "repo.git"))
		self.forward_repo_url = os.path.join(self.repo_dir, "forwardrepo.git")
		Repo.init(self.forward_repo_url, bare=True)

		self.change_verifier = VerificationRoundTripTest.TestChangeVerifier(self.verifier_pool)
		verification_server = VerificationServer(self.change_verifier)

		self.vs_greenlet = verification_server.run()

		StoreSettings.ssh_private_key = 'privatekey'

		with ConnectionFactory.get_sql_connection() as conn:
			ins_user = schema.user.insert().values(email="bbland@lt3.com", first_name="brian", last_name="bland", password_hash=binascii.b2a_base64(sha512("").digest())[0:-1], salt="1234567890123456", created=0)
			self.user_id = conn.execute(ins_user).inserted_primary_key[0]

	def tearDown(self):
		rmtree(self.repo_dir)
		self.vs_greenlet.kill()
		self._stop_redis()
		self._purge_queues()
		super(VerificationRoundTripTest, self).tearDown()

	def _insert_repo_info(self, repo_uri):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_machine = schema.repostore.insert().values(ip_address="127.0.0.1", repositories_path=self.repo_dir)
			repostore_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(id=self.repo_id, name="repo", repostore_id=repostore_key, uri=repo_uri,
				forward_url=self.forward_repo_url, created=120929, type="git")
			repo_key = conn.execute(ins_repo).inserted_primary_key[0]
			return repo_key

	def _on_response(self, body, message):
		message.channel.basic_ack(delivery_tag=message.delivery_tag)
		if body["type"] == "change finished":
			self.verification_status = body["contents"]["verification_status"]
			self.merge_status = body["contents"].get("merge_status")

	def _test_commands(self, passes):
		num_commands = 5
		if passes:
			return [{'pass': {'script': ['echo hi', 'echo bye', 'true']}} for x in xrange(num_commands)]
		else:
			return [{'pass': {'script': 'true'}} for x in xrange(num_commands - 1)] + [{'fail': {'script': 'false'}}]

	def _repo_roundtrip(self, modfile, contents, passes=True):
		repo_id = self._insert_repo_info(self.repo_path)

		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(self.repostore_id)) as client:
			client.create_repository(self.repo_id, "repo")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._git_modify_commit_push(work_repo, modfile, contents, parent_commits=[])

		with model_server.rpc_connect("changes", "create") as client:
			commit_id = client.create_commit_and_change(self.repo_id, self.user_id, None, bare_repo.head.commit.hexsha, 'master', False)['commit_id']

		commit_sha = self._git_modify_commit_push(work_repo, "koality.yml",
			yaml.safe_dump({'test': {'scripts': self._test_commands(passes)}}),
			parent_commits=[init_commit], refspec="HEAD:refs/pending/%d" % commit_id).hexsha

		with Connection(RabbitSettings.kombu_connection_info) as connection:
			Queue("verification:repos.update", EventsBroker.events_exchange, routing_key="repos", durable=False)(connection).declare()
			events_broker = EventsBroker(connection)
			with events_broker.subscribe("repos", callback=self._on_response) as consumer:
				self.verification_status = None
				start_time = time.time()
				consumer.consume()
				while self.verification_status is None:
					try:
						connection.drain_events(timeout=1)
					except socket.timeout:
						pass
					assert time.time() - start_time < 120  # 120s timeout

		self.change_verifier._change_finished.wait()
		work_repo.git.fetch()
		work_repo.git.checkout('origin/master')
		return commit_sha, work_repo

	def _patch_roundtrip(self, modfile, contents, passes=True):
		repo_id = self._insert_repo_info(self.repo_path)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			last_commit_id = sqlconn.execute(func.max(schema.commit.c.id)).first()[0]
			commit_id = last_commit_id + 1 if last_commit_id else 1

		with Client(StoreSettings.rpc_exchange_name, RepositoryStore.queue_name(self.repostore_id)) as client:
			client.create_repository(self.repo_id, "repo")

		bare_repo = Repo.init(self.repo_path, bare=True)
		work_repo = bare_repo.clone(bare_repo.working_dir + ".clone")

		init_commit = self._git_modify_commit_push(work_repo, modfile, contents, parent_commits=[])

		commit_sha = self._git_modify_commit_push(work_repo, "koality.yml",
			yaml.safe_dump({'test': {'scripts': self._test_commands(passes)}}),
			parent_commits=[init_commit], refspec="HEAD:refs/pending/%d" % commit_id).hexsha

		with open(os.path.join(work_repo.working_dir, 'makeapatch'), "w") as f:
			f.write('patchstuffs')

		work_repo.index.add(['makeapatch'])
		work_repo.index.commit('temporary patch commit', parent_commits=[commit_sha])

		patch = work_repo.git.format_patch(commit_sha, stdout=True)
		work_repo.git.reset('HEAD~', hard=True)

		with model_server.rpc_connect("changes", "create") as client:
			client.create_commit_and_change(self.repo_id, self.user_id, None, bare_repo.head.commit.hexsha, 'master', False, patch)

		with Connection(RabbitSettings.kombu_connection_info) as connection:
			Queue("verification:repos.update", EventsBroker.events_exchange, routing_key="repos", durable=False)(connection).declare()
			events_broker = EventsBroker(connection)
			with events_broker.subscribe("repos", callback=self._on_response) as consumer:
				self.verification_status = None
				start_time = time.time()
				consumer.consume()
				while self.verification_status is None:
					try:
						connection.drain_events(timeout=1)
					except socket.timeout:
						pass
					assert time.time() - start_time < 120  # 120s timeout

		return commit_sha, work_repo

	def test_passing_roundtrip(self):
		DeploymentSettings.active = True
		commit_sha, work_repo = self._repo_roundtrip("test.txt", "c1")
		assert_equal(BuildStatus.PASSED, self.verification_status)
		assert_equal(commit_sha, work_repo.head.commit.hexsha)

	def test_failing_roundtrip(self):
		DeploymentSettings.active = True
		commit_sha, work_repo = self._repo_roundtrip("test.txt", "c1", passes=False)
		assert_equal(BuildStatus.FAILED, self.verification_status)
		assert_not_equal(commit_sha, work_repo.head.commit.hexsha)

	def test_roundtrip_with_patch(self):
		DeploymentSettings.active = True
		commit_sha, work_repo = self._patch_roundtrip("test.txt", "c1")
		assert_equal(BuildStatus.PASSED, self.verification_status)

	def test_roundtrip_with_postmerge_success(self):
		DeploymentSettings.active = True
		forward_repo = Repo(self.forward_repo_url)
		work_repo = forward_repo.clone(forward_repo.working_dir + ".clone")

		self._git_modify_commit_push(work_repo, "other.txt", "c2")
		commit_sha, work_repo = self._repo_roundtrip("test.txt", "c1")
		assert_equal(BuildStatus.PASSED, self.verification_status)
		assert_equal(MergeStatus.PASSED, self.merge_status)
		assert_not_equal(commit_sha, work_repo.head.commit.hexsha)

	def test_roundtrip_with_postmerge_failure(self):
		DeploymentSettings.active = True
		forward_repo = Repo(self.forward_repo_url)
		work_repo = forward_repo.clone(forward_repo.working_dir + ".clone")

		conflict_sha = self._git_modify_commit_push(work_repo, "conflict.txt", "c2").hexsha
		self._repo_roundtrip("conflict.txt", "conflict")
		assert_equal(BuildStatus.PASSED, self.verification_status)
		assert_equal(MergeStatus.FAILED, self.merge_status)
		assert_equal(conflict_sha, work_repo.head.commit.hexsha)

	def test_skip_roundtrip(self):
		DeploymentSettings.active = False
		commit_sha, work_repo = self._repo_roundtrip("test.txt", "c1")
		assert_equal(BuildStatus.SKIPPED, self.verification_status)
		assert_equal(commit_sha, work_repo.head.commit.hexsha)
