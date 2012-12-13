import database.schema

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class BuildsCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildsCreateHandler, self).__init__("builds", "create")

	def create_build(self, change_id, commit_list, is_primary=False):
		build = database.schema.build

		ins = build.insert().values(change_id=change_id, is_primary=is_primary,
			status=BuildStatus.QUEUED)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
			build_id = result.inserted_primary_key[0]

		build_commits_map = database.schema.build_commits_map

		with ConnectionFactory.get_sql_connection() as sqlconn:
			for commit in commit_list:
				ins = build_commits_map.insert().values(build_id=build_id, commit_id=commit)
				sqlconn.execute(ins)

		self.publish_event("changes", change_id, "build added", build_id=build_id, commit_list=commit_list)
		return build_id
