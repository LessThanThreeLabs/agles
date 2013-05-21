from nose.tools import *

import model_server

from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from util.permissions import InvalidPermissionsError
from util.shell import *
from database.engine import ConnectionFactory
from database import schema

VALID_COMMANDS = [
	'git-receive-pack',
	'git-upload-pack'
]

USER_ID_COMMANDS = ['git-receive-pack']

NON_EXISTANT_USER_ID = "0"


class ShellTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	@classmethod
	def setup_class(cls):
		super(ShellTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(ShellTest, self).setUp()
		self._start_model_server()

	def tearDown(self):
		super(ShellTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def _create_repo_store(self):
		ins = schema.repostore.insert().values(ip_address="127.0.0.1", repositories_path="/tmp")
		with ConnectionFactory.get_sql_connection() as conn:
			result = conn.execute(ins)
			return result.inserted_primary_key[0]

#TODO: FIX THIS HAX WITH CREATE REPO
	def _setup_db_entries(self, REPO_URI):
		repostore_id = self._create_repo_store()
		with model_server.rpc_connect("repos", "create") as rpc_conn:
			rpc_conn._create_repo_in_db(1, "repo.git", REPO_URI, repostore_id, "forwardurl", 0)
		with model_server.rpc_connect("users", "create") as rpc_conn:
			self.user_id = rpc_conn.create_user("email", "first_name", "last_name", "hash", "salt")

	def test_new_sshargs(self):
		REPO_URI = "schacon/repo.git"
		self._setup_db_entries(REPO_URI)

		rsh = RestrictedGitShell(VALID_COMMANDS, USER_ID_COMMANDS)
		sshargs = rsh.rp_new_sshargs('git-receive-pack', REPO_URI, str(self.user_id))

		assert_equal(len(sshargs), 7)
		assert_equal('ssh', sshargs[0])
		assert_equal('ssh', sshargs[1])
		assert_equal('-p', sshargs[2])
		assert_equal('2222', sshargs[3])
		assert_equal('-oStrictHostKeyChecking=no', sshargs[4])
		assert_equal('git@127.0.0.1', sshargs[5])
		assert_is_not_none(re.match("git-receive-pack '.+/.+/.+/repo.git' 1", sshargs[6]),
			msg='Created ssh command: "%s" is not well formed.' % sshargs[6])

	def test_invalid_permissions(self):
		REPO_URI = "schacon/repo.git"
		self._setup_db_entries(REPO_URI)

		rsh = RestrictedGitShell(VALID_COMMANDS, USER_ID_COMMANDS)
		assert_raises(InvalidPermissionsError, rsh.rp_new_sshargs, 'git-upload-pack', REPO_URI, NON_EXISTANT_USER_ID)
