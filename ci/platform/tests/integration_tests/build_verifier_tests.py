from nose.tools import *

import model_server

from database import schema
from database.engine import ConnectionFactory
from shared.constants import BuildStatus
from util.test import BaseIntegrationTest
from util.test.fake_build_verifier import FakeBuildCore
from util.test.mixins import ModelServerTestMixin, RabbitMixin, RedisTestMixin
from verification.build_verifier import BuildVerifier


class BuildVerifierTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin, RedisTestMixin):
	@classmethod
	def setup_class(cls):
		super(BuildVerifierTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(BuildVerifierTest, self).setUp()
		self._start_model_server()
		self._start_redis()

	def tearDown(self):
		super(BuildVerifierTest, self).tearDown()
		self._stop_redis()
		self._stop_model_server()
		self._purge_queues()

	def _insert_repo_info(self, repo_id):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_machine = schema.repostore.insert().values(ip_address="127.0.0.1", repositories_path='/repos/path')
			repostore_key = conn.execute(ins_machine).inserted_primary_key[0]
			ins_repo = schema.repo.insert().values(id=repo_id, name="repo.git", repostore_id=repostore_key, uri='repo/uri',
				forward_url='forward/url', created=120929)
			conn.execute(ins_repo)

	def _insert_commit_info(self, commit_id, change_id, repo_id):
		with ConnectionFactory.get_sql_connection() as conn:
			ins_commit = schema.commit.insert().values(id=commit_id, repo_id=repo_id,
				user_id=1, message="commit message", sha="sha", timestamp=8675309)
			conn.execute(ins_commit)
			ins_change = schema.change.insert().values(id=change_id, commit_id=commit_id, repo_id=repo_id, merge_target="master",
				number=1, verification_status=BuildStatus.QUEUED, create_time=8675309)
			conn.execute(ins_change)

	def test_handle_interrupted_queued_build(self):
		commit_id, change_id, repo_id = 42, 69, 13

		self._insert_repo_info(repo_id)
		self._insert_commit_info(commit_id, change_id, repo_id)

		with model_server.rpc_connect("builds", "create") as builds_create_rpc:
			build_id = builds_create_rpc.create_build(change_id)

		self._assert_build_status(build_id, BuildStatus.QUEUED)
		self._assert_change_verification_status(change_id, BuildStatus.QUEUED)

		build_core = FakeBuildCore(1337)
		build_core.virtual_machine.store_vm_info()
		build_core.virtual_machine.store_vm_metadata(build_id=build_id)

		build_verifier = BuildVerifier(build_core)

		self._assert_build_status(build_id, BuildStatus.FAILED)
		self._assert_change_verification_status(change_id, BuildStatus.FAILED)

	def test_handle_interrupted_running_build(self):
		commit_id, change_id, repo_id = 42, 69, 13

		self._insert_repo_info(repo_id)
		self._insert_commit_info(commit_id, change_id, repo_id)

		with model_server.rpc_connect("builds", "create") as builds_create_rpc:
			build_id = builds_create_rpc.create_build(change_id)

		self._assert_build_status(build_id, BuildStatus.QUEUED)
		self._assert_change_verification_status(change_id, BuildStatus.QUEUED)

		with model_server.rpc_connect("changes", "update") as changes_update_rpc:
			changes_update_rpc.mark_change_started(change_id)

		with model_server.rpc_connect("builds", "update") as builds_update_rpc:
			builds_update_rpc.start_build(build_id)

		self._assert_build_status(build_id, BuildStatus.RUNNING)
		self._assert_change_verification_status(change_id, BuildStatus.RUNNING)

		build_core = FakeBuildCore(1337)
		build_core.virtual_machine.store_vm_info()
		build_core.virtual_machine.store_vm_metadata(build_id=build_id)

		build_verifier = BuildVerifier(build_core)

		self._assert_build_status(build_id, BuildStatus.FAILED)
		self._assert_change_verification_status(change_id, BuildStatus.FAILED)

	def test_handle_interrupted_build_on_passed_change(self):
		commit_id, change_id, repo_id = 42, 69, 13

		self._insert_repo_info(repo_id)
		self._insert_commit_info(commit_id, change_id, repo_id)

		with model_server.rpc_connect("builds", "create") as builds_create_rpc:
			build_id = builds_create_rpc.create_build(change_id)

		self._assert_build_status(build_id, BuildStatus.QUEUED)
		self._assert_change_verification_status(change_id, BuildStatus.QUEUED)

		build_core = FakeBuildCore(1337)
		build_core.virtual_machine.store_vm_info()
		build_core.virtual_machine.store_vm_metadata(build_id=build_id)

		with model_server.rpc_connect("changes", "update") as changes_update_rpc:
			changes_update_rpc.mark_change_finished(change_id, BuildStatus.PASSED)

		self._assert_build_status(build_id, BuildStatus.QUEUED)
		self._assert_change_verification_status(change_id, BuildStatus.PASSED)

		build_verifier = BuildVerifier(build_core)

		self._assert_build_status(build_id, BuildStatus.FAILED)
		self._assert_change_verification_status(change_id, BuildStatus.PASSED)

	def _assert_build_status(self, build_id, status):
		with model_server.rpc_connect("builds", "read") as builds_read_rpc:
			assert_equal(builds_read_rpc.get_build_from_id(build_id)['status'], status)

	def _assert_change_verification_status(self, change_id, verification_status):
		with model_server.rpc_connect("changes", "read") as changes_read_rpc:
			assert_equal(changes_read_rpc.get_change_attributes(change_id)['verification_status'], verification_status)
