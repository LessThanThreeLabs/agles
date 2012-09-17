from nose.tools import *

from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin
from util.shell import *
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
		with EngineFactory.get_connection() as conn:
			result = conn.execute(ins)
			return result.inserted_primary_key[0]

	def _map_uri(self, repo_uri, repo_id):
		ins = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_id)
		with EngineFactory.get_connection() as conn:
			conn.execute(ins)

	def test_reroute_param_generation(self):
		REPO_URI = "schacon/repo.git"
		machine_id = self._create_repo_store_machine()

		rpc_conn = ModelServer.rpc_connect()
		try:
			repo_id = rpc_conn.create_repo("repo.git", machine_id)
		finally:
			rpc_conn.close()

		self._map_uri(REPO_URI, repo_id)

		rsh = RestrictedShell(VALID_COMMANDS)
		route, path = rsh._get_requested_params(REPO_URI)
		assert_equals(route, "http://machine0")
		assert_not_equals(path.find("repo.git"), -1,
						  msg="Incorrect repo for path: %s" % path)
		assert_equals(path.count('/'), 3,
					  msg="Incorrect directory levels for path: %s" % path)
