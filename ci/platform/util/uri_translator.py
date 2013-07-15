import model_server


class RepositoryUriTranslator(object):
	def translate(self, repo_uri):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			attributes = model_server_rpc.get_repo_attributes(repo_uri)
		return "git@%s:%s" % (attributes['repostore']['ip_address'], repo_uri)

	def extract_repo_name(self, repo_uri):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			attributes = model_server_rpc.get_repo_attributes(repo_uri)
		return attributes['repo']['name']
