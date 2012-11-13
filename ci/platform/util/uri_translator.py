import os

from model_server import ModelServer
from util import pathgen


class RepositoryUriTranslator(object):
	def translate(self, repo_uri):
		with ModelServer.rpc_connect("repos", "read") as model_server_rpc:
			route, repos_path, repo_hash, repo_name = model_server_rpc.get_repo_attributes(repo_uri)
		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_hash, repo_name))
		return "git@%s:%s" % (route, remote_filesystem_path)
