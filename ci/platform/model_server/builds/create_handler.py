import time

import database.schema

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class BuildsCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildsCreateHandler, self).__init__("builds", "create")

	def create_build(self, change_id, commit_list):
		build = database.schema.build
		change = database.schema.change

		create_time = int(time.time())

		query = change.select().where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			change_row = sqlconn.execute(query).first()
			assert change_row is not None
			ins = build.insert().values(change_id=change_id, repo_id=change_row[change.c.repo_id],
				status=BuildStatus.QUEUED, create_time=create_time)
			result = sqlconn.execute(ins)
			build_id = result.inserted_primary_key[0]

		build_commits_map = database.schema.build_commits_map

		with ConnectionFactory.get_sql_connection() as sqlconn:
			for commit in commit_list:
				ins = build_commits_map.insert().values(build_id=build_id, commit_id=commit)
				sqlconn.execute(ins)

		self.publish_event("changes", change_id, "build added", build_id=build_id, commit_list=commit_list, create_time=create_time)
		return build_id
