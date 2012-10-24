import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class BuildsReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildsReadHandler, self).__init__("builds", "read")

	def get_build_attributes(self, build_id):
		build = database.schema.build
		query = build.select().where(build.c.id==build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return (row[build.c.change_id], row[build.c.is_primary],
				row[build.c.status], row[build.c.start_time],
				row[build.c.end_time])

	def get_commit_list(self, build_id):
		build_commits_map = database.schema.build_commits_map
		query = build_commits_map.select().where(build_commits_map.c.build_id==build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [row[build_commits_map.c.commit_id] for row in sqlconn.execute(query)]
