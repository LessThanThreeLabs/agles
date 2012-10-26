from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.database import to_dict


class BuildsReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildsReadHandler, self).__init__("builds", "read")

	def get_build_from_id(self, build_id):
		build = database.schema.build
		query = build.select().where(build.c.id==build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return to_dict(row, build.columns)

	def get_commit_list(self, build_id):
		build_commits_map = database.schema.build_commits_map
		query = build_commits_map.select().where(build_commits_map.c.build_id==build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [row[build_commits_map.c.commit_id] for row in sqlconn.execute(query)]

	# TODO (jchu): code this function
	def _has_permissions(self, user_id, obj):
		return True

	# TODO (jchu): we currently do nothing with the :type: parameter
	def get_builds_in_range(self, user_id, repo_id, type, start_index_inclusive,
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
			builds = map(lambda row: to_dict(row, build.columns), sqlconn.execute(query))
		return filter(lambda build: self._has_permissions(user_id, build), builds)
