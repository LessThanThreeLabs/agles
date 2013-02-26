from sqlalchemy import or_

import collections
import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict, load_temp_strings
from util.permissions import InvalidPermissionsError


class ChangesReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesReadHandler, self).__init__("changes", "read")

	def get_change_attributes(self, change_id):
		change = database.schema.change
		query = change.select().where(change.c.id == change_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return to_dict(row, change.columns)

	def get_builds_from_change_id(self, change_id):
		build = database.schema.build

		query = build.select().where(build.c.change_id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [to_dict(row, build.columns) for row in sqlconn.execute(query)]

##########################
# Front end API
##########################

	def get_visible_change_from_id(self, user_id, change_id):
		change = database.schema.change
		repo = database.schema.repo

		query = change.join(repo).select().apply_labels().where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			repo_id = row[repo.c.id]
			return to_dict(row, change.columns, tablename=change.name)
		return {}

	def get_change_metadata(self, user_id, change_id):
		change = database.schema.change
		commit = database.schema.commit
		user = database.schema.user

		query = change.join(commit).join(user).select().apply_labels().where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			repo_id = row[change.c.repo_id]
			user_dict = to_dict(row, user.columns, tablename=user.name)
			change_dict = to_dict(row, change.columns, tablename=change.name)
			commit_dict = to_dict(row, commit.columns, tablename=commit.name)
			return {
				'user': user_dict,
				'change': change_dict,
				'commit': commit_dict,
			}

		raise InvalidPermissionsError(user_id, change_id)

	def get_visible_builds_from_change_id(self, user_id, change_id):
		build = database.schema.build
		change = database.schema.change
		repo = database.schema.repo

		query = build.join(change).join(repo).select().apply_labels().where(
			change.c.id == change_id
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			repo_id = row[repo.c.id]
			return self.get_builds_from_change_id(change_id)
		return {}

	VALID_GROUPS = ["all", "me"]

	# TODO (jchu): This query is SLOW AS BALLS
	def query_changes_group(self, user_id, repo_id, group, start_index_inclusive, num_results):
		assert group in self.VALID_GROUPS

		user = database.schema.user
		change = database.schema.change
		commit = database.schema.commit

		query = change.join(commit).join(user).select()
		query = query.apply_labels().where(change.c.repo_id == repo_id)
		if group == "me":
			query = query.where(user.c.id == user_id)
		query = query.order_by(change.c.number.desc()).limit(num_results).offset(start_index_inclusive)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			changes = map(lambda row: to_dict(row, change.columns, tablename=change.name), sqlconn.execute(query))
		return changes

	def query_changes_filter(self, user_id, repo_id, names_filter, start_index_inclusive, num_results):
		assert isinstance(names_filter, collections.Iterable)
		assert not isinstance(names_filter, str)

		if not names_filter:
			return self.query_changes_group(user_id, repo_id, "all", start_index_inclusive, num_results)

		user = database.schema.user
		change = database.schema.change
		commit = database.schema.commit
		temp_string = database.schema.temp_string

		query = change.join(commit).join(user).join(
			temp_string,
			or_(
				temp_string.c.string == user.c.first_name,
				temp_string.c.string == user.c.last_name
			)
		)

		query = query.select().apply_labels().where(change.c.repo_id == repo_id).distinct(change.c.number)
		query = query.order_by(change.c.number.desc()).limit(num_results).offset(
			start_index_inclusive)

		with ConnectionFactory.transaction_context() as sqlconn:
			load_temp_strings(names_filter)
			changes = map(lambda row: to_dict(row, change.columns,
				tablename=change.name), sqlconn.execute(query))
		return changes

	def can_hear_change_events(self, user_id, id_to_listen_to):
		return True
