from nose.tools import *

from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from util.permissions import RepositoryPermissions, InvalidPermissionsError
from util.shell import *
from database.engine import ConnectionFactory
from database import schema

COMMANDS_TO_PERMISSIONS = {
	'git-receive-pack': RepositoryPermissions.NONE,
	'git-upload-pack': RepositoryPermissions.RWA
}

USER_ID_COMMANDS = ['git-receive-pack']


class ShellTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	def setUp(self):
		super(ShellTest, self).setUp()
		self._purge_queues()
		self._start_model_server()

	def tearDown(self):
		super(ShellTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def _create_repo_store(self):
		ins = schema.repostore.insert().values(uri="afjfaio", host_name="localhost", repositories_path="/tmp")
		with ConnectionFactory.get_sql_connection() as conn:
			result = conn.execute(ins)
			return result.inserted_primary_key[0]

	def _map_uri(self, repo_uri, repo_id):
		ins = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_id)
		with ConnectionFactory.get_sql_connection() as conn:
			conn.execute(ins)

#TODO: FIX THIS HAX WITH CREATE REPO
	def _setup_db_entries(self, REPO_URI):
		repostore_id = self._create_repo_store()
		with ModelServer.rpc_connect("repos", "create") as rpc_conn:
			repo_id = rpc_conn._create_repo_in_db("repo.git", "repo.git", "afjfaio", RepositoryPermissions.RW)
		self._map_uri(REPO_URI, repo_id)

	def test_new_sshargs(self):
		REPO_URI = "schacon/repo.git"
		self._setup_db_entries(REPO_URI)

		rsh = RestrictedGitShell(COMMANDS_TO_PERMISSIONS, USER_ID_COMMANDS)
		sshargs = rsh.new_sshargs('git-receive-pack', REPO_URI, "1")

		assert_equals(len(sshargs), 8)
		assert_equals('ssh', sshargs[0])
		assert_equals('ssh', sshargs[1])
		assert_equals('-p', sshargs[2])
		assert_equals('2222', sshargs[3])
		assert_equals('-o', sshargs[4])
		assert_equals('StrictHostKeyChecking=false', sshargs[5])
		assert_equals('git@localhost', sshargs[6])
		assert_is_not_none(re.match("git-receive-pack '.+/.+/.+/repo.git' 1", sshargs[7]),
			msg='Created ssh command: "%s" is not well formed.' % sshargs[7])

	def test_invalid_permissions(self):
		REPO_URI = "schacon/repo.git"
		self._setup_db_entries(REPO_URI)

		rsh = RestrictedGitShell(COMMANDS_TO_PERMISSIONS, USER_ID_COMMANDS)
		assert_raises(InvalidPermissionsError, rsh.new_sshargs, 'git-upload-pack', REPO_URI, "2")
