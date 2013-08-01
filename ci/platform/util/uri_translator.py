import model_server


class RepositoryUriTranslator(object):
	def translate(self, repo_uri):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repostore_id, route, repos_path, repo_id, repo_name, repo_type = model_server_rpc.get_repo_attributes(repo_uri)
		if repo_type == 'git':
			return "git@%s:%s" % (route, repo_uri)
		elif repo_type == 'hg':
			# Note that we are making the assumption that the route will never contain any slashes.
			return "ssh://git@%s/%s" % (route, repo_uri)

	def extract_repo_name(self, repo_uri):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repostore_id, route, repos_path, repo_id, repo_name, repo_type = model_server_rpc.get_repo_attributes(repo_uri)
		return repo_name
