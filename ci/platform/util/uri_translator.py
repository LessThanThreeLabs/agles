import model_server


class RepositoryUriTranslator(object):
	def translate(self, repo_uri):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repostore_id, route, repos_path, repo_id, repo_name, private_key = model_server_rpc.get_repo_attributes(repo_uri)
		return "git@%s:%s" % (route, repo_uri)

	def extract_repo_name(self, repo_uri):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repostore_id, route, repos_path, repo_id, repo_name, private_key = model_server_rpc.get_repo_attributes(repo_uri)
		return repo_name
