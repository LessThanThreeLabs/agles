import database.schema

from sqlalchemy import and_, or_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict
from util.permissions import has_repo_permissions, InvalidPermissionsError


class ChangesReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesReadHandler, self).__init__("changes", "read")

	def get_change_attributes(self, change_id):
		change = database.schema.change
		query = change.select().where(change.c.id==change_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return (row[change.c.commit_id], row[change.c.merge_target],
				row[change.c.number], row[change.c.status],
				row[change.c.start_time], row[change.c.end_time])

	def get_builds_from_change_id(self, change_id):
		build = database.schema.build

		query = build.select().where(build.c.change_id==change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [to_dict(row, build.columns) for row in sqlconn.execute(query)]

##########################
# Front end API
##########################

	def get_visible_change_from_id(self, user_id, change_id):
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo

		query = change.join(commit).join(repo).select().apply_labels().where(change.c.id==change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			repo_id = row[repo.c.id]
			if has_repo_permissions(user_id, repo_id):
				return to_dict(row, change.columns, tablename=change.name)
			else:
				raise InvalidPermissionsError("user_id: %d, repo_id: %d"
											  % (user_id, repo_id))
		return {}

	def get_visible_builds_from_change_id(self, user_id, change_id):
		build = database.schema.build
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo

		query = build.join(change).join(commit).join(repo).select().apply_labels().where(
			change.c.id==change_id
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			repo_id = row[repo.c.id]
			if has_repo_permissions(user_id, repo_id):
				return self.get_builds_from_change_id(change_id)
			else:
				raise InvalidPermissionsError("user_id: %d, repo_id: %d"
											  % (user_id, repo_id))
		return {}

	# TODO (jchu): This query is SLOW AS BALLS
	def query_changes(self, user_id, repo_id, query_string,
					  start_index_inclusive, num_results):
		user = database.schema.user
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo

		if not has_repo_permissions(user_id, repo_id):
			raise InvalidPermissionsError("user_id: %d, repo_id %d"
										  % (user_id, repo_id))

		query_string = "%" + query_string + "%"

		query = change.join(commit).join(repo).join(user).select().apply_labels().where(
			and_(
				repo.c.id==repo_id,
				or_(
					commit.c.message.like(query_string),
					user.c.email.like(query_string)
				)
			)
		)
		query = query.order_by(change.c.number.desc()).limit(num_results).offset(
			start_index_inclusive)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			builds = map(lambda row: to_dict(row, change.columns,
				tablename=change.name), sqlconn.execute(query))
			return builds
