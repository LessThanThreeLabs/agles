
from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ReposUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ReposUpdateHandler, self).__init__("repos", "update")

#####################
# Github Integration
#####################

	def set_corresponding_github_repo_url(self, repo_id, github_repo_url):
		github_repo_url_map = schema.github_repo_url_map
		ins = github_repo_url_map.insert().values(
			repo_id=repo_id,
			github_url=github_repo_url
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(ins)
