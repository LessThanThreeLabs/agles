from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.database import to_dict


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

	def get_builds_in_range(self, user, repo_id, type, start_index_inclusive,
							end_index_exclusive):
		build = database.schema.build
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo
		query = build.join(change).join(commit).join(repo).select().where(
			and_(
				repo.c.id==repo_id,
				build.c.id >= start_index_inclusive,
				build.c.id < end_index_exclusive,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return map(lambda row: to_dict(row, build.columns), sqlconn.execute(query))
