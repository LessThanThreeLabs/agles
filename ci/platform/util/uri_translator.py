from model_server import ModelServer


class RepositoryUriTranslator(object):
	def translate(self, repo_uri):
		with ModelServer.rpc_connect("repos", "read") as model_server_rpc:
			route, repos_path, repo_hash, repo_name = model_server_rpc.get_repo_attributes(repo_uri)
		return "git@%s:%s" % (route, repo_uri)
