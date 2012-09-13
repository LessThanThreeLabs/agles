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
	model_server_rpc_conn = ModelServer()
	REPO_URI = "schacon/repo.git"
	machine_id = _create_repo_store_machine()
	repo_id = model_server_rpc_conn.create_repo("repo.git", machine_id)
	
	_map_uri(REPO_URI, repo_id)
	
	rsh = RestrictedShell(VALID_COMMANDS)
	rsh._get_requested_params(REPO_URI)