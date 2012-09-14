from nose.tools import *
from util.shell import *

import zerorpc

from multiprocessing import Process

from database.engine import EngineFactory
from database import schema
from model_server import ModelServer
from settings.model_server import model_server_rpc_address


VALID_COMMANDS = ['git-receive-pack']

def setup():
	pass

def teardown():
	pass

def _create_repo_store_machine():
	ins = schema.machine.insert().values(uri="http://machine0")
	with EngineFactory.get_connection() as conn:
		result = conn.execute(ins)
		return result.inserted_primary_key[0]

def _map_uri(repo_uri, repo_id):
	ins = schema.uri_repo_map.insert().values(uri=repo_uri, repo_id=repo_id)
	with EngineFactory.get_connection() as conn:
		conn.execute(ins)

def test_reroute_param_generation():
	REPO_URI = "schacon/repo.git"
	machine_id = _create_repo_store_machine()
	
	try:
		rpc_conn = ModelServer.rpc_connect()
		repo_id = rpc_conn.create_repo("repo.git", machine_id)
	finally:
		rpc_conn.close()
	
	_map_uri(REPO_URI, repo_id)
	
	rsh = RestrictedShell(VALID_COMMANDS)
	route, path = rsh._get_requested_params(REPO_URI)
	assert_equals(route, "http://machine0")
	assert_not_equals(path.find("repo.git"), -1,
					  msg="Incorrect repo for path: %s" % path)
	assert_equals(path.count('/'), 3,
				  msg="Incorrect directory levels for path: %s" % path)
