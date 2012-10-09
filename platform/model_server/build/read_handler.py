import database.schema

from model_server.rpc_handler import ModelServerRpcHandler


class BuildReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildReadHandler, self).__init__("build", "read")

	def get_build_attributes(self, build_id):
		build = database.schema.build
		query = build.select().where(build.c.id==build_id)
		row = self._db_conn.execute(query).first()
		if row:
			return (row[build.c.change_id], row[build.c.is_primary],
				row[build.c.status], row[build.c.start_time],
				row[build.c.end_time])

	def get_commit_list(self, build_id):
		build_commits_map = database.schema.build_commits_map
		query = build_commits_map.select().where(build_commits_map.c.build_id==build_id)
		return [row[build_commits_map.c.commit_id] for row in self._db_conn.execute(query)]
