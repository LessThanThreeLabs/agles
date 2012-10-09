from nose.tools import *

from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin
from util.shell import *
from database.engine import ConnectionFactory
from database import schema

VALID_COMMANDS = ['git-receive-pack']


class ShellTest(BaseIntegrationTest, ModelServerTestMixin):
	def setUp(self):
		super(ShellTest, self).setUp()
		self._start_model_server()

	def tearDown(self):
		super(ShellTest, self).tearDown()
		self._stop_model_server()

	def _create_repo_store_machine(self):
		ins = schema.machine.insert().values(uri="http://machine0")
		with ConnectionFactory.get_sql_connection() as conn:
			result = conn.execute(ins)
			return result.inserted_primary_key[0]

	def _map_uri(self, repo_uri, repo_id):
		ins = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_id)
		with ConnectionFactory.get_sql_connection() as conn:
			conn.execute(ins)

	def _setup_db_entries(self, REPO_URI):
		machine_id = self._create_repo_store_machine()
		with ModelServer.rpc_connect("repo", "create") as rpc_conn:
			repo_id = rpc_conn.create_repo("repo.git", machine_id)
		self._map_uri(REPO_URI, repo_id)

	def test_reroute_param_generation(self):
		REPO_URI = "schacon/repo.git"
		self._setup_db_entries(REPO_URI)

		rsh = RestrictedGitShell(VALID_COMMANDS)
		route, path = rsh._get_route_path(REPO_URI)
		assert_equals(route, "http://machine0")
		assert_not_equals(path.find("repo.git"), -1,
						  msg="Incorrect repo for path: %s" % path)
		assert_equals(path.count('/'), 3,
					  msg="Incorrect directory levels for path: %s" % path)

	def test_new_sshargs(self):
		REPO_URI = "schacon/repo.git"
		self._setup_db_entries(REPO_URI)

		rsh = RestrictedGitShell(VALID_COMMANDS)
		sshargs = rsh.new_sshargs('git-receive-pack', REPO_URI, "1")

		assert_equals(len(sshargs), 3)
		assert_equals('ssh', sshargs[0])
		assert_equals('git@http://machine0', sshargs[1])
		assert_is_not_none(re.match("git-receive-pack '././.+/repo.git' 1", sshargs[2]), msg="Created ssh command is not well formed.")

