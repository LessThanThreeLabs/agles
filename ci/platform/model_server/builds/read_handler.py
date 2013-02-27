from sqlalchemy import and_, or_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict


class BuildsReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildsReadHandler, self).__init__("builds", "read")

	def get_build_from_id(self, build_id):
		build = database.schema.build

		query = build.select().where(build.c.id == build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return to_dict(row, build.columns)

	def get_commit_list(self, build_id):
		build_commits_map = database.schema.build_commits_map
		query = build_commits_map.select().where(build_commits_map.c.build_id == build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [row[build_commits_map.c.commit_id] for row in sqlconn.execute(query)]

##################
# Front end API
##################

	def get_visible_build_from_id(self, user_id, build_id):
		build = database.schema.build
		repo = database.schema.repo

		query = build.join(repo).select().apply_labels().where(build.c.id == build_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			return to_dict(row, build.columns, tablename=build.name)
		return {}

	# TODO (jchu): This query is SLOW AS BALLS
	def query_builds(self, user_id, repo_id, query_string, start_index_inclusive, num_results):
		user = database.schema.user
		build = database.schema.build
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo

		query_string = "%" + query_string + "%"

		query = build.join(change).join(commit).join(repo).join(user).select().apply_labels().where(
			and_(
				repo.c.id == repo_id,
				or_(
					commit.c.message.like(query_string),
					user.c.email.like(query_string)
				)
			)
		)
		query = query.order_by(build.c.id.desc()).limit(num_results).offset(
			start_index_inclusive)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			builds = map(lambda row: to_dict(row, build.columns,
				tablename=build.name), sqlconn.execute(query))
			return builds
