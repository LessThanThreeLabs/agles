from sqlalchemy import cast, func, and_, or_, Integer

import collections
import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict, load_temp_strings


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

	def get_patch(self, patch_id):
		patch = database.schema.patch
		query = patch.select().where(patch.c.id == patch_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			if row:
				return to_dict(row, patch.columns)

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
			return to_dict(row, change.columns, tablename=change.name)
		return {}

	def get_change(self, user_id, change_id):
		change = database.schema.change
		commit = database.schema.commit
		user = database.schema.user

		query = change.join(commit).join(user).select().apply_labels().where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			return dict(to_dict(row, change.columns, tablename=change.name), **{
				'user': to_dict(row, user.columns, tablename=user.name),
				'commit': to_dict(row, commit.columns, tablename=commit.name),
			})

		raise NoSuchChangeError(change_id)

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
			return self.get_builds_from_change_id(change_id)
		return {}

	VALID_GROUPS = ["all", "me"]

	# TODO (jchu): This query is SLOW AS BALLS
	def query_changes_group(self, user_id, repo_ids, group, start_index_inclusive, num_results):
		assert isinstance(repo_ids, collections.Iterable)
		assert not isinstance(repo_ids, (str, unicode))

		assert group in self.VALID_GROUPS

		if not repo_ids:
			return []

		user = database.schema.user
		change = database.schema.change
		commit = database.schema.commit

		query = change.join(commit).join(user).select()
		query = query.apply_labels().where(
			or_(*[change.c.repo_id == repo_id for repo_id in repo_ids])
		)
		if group == "me":
			query = query.where(user.c.id == user_id)
		query = query.order_by(change.c.create_time.desc()).limit(num_results).offset(start_index_inclusive)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			changes = map(lambda row: dict(to_dict(row, change.columns, tablename=change.name), **{
				'user': to_dict(row, user.columns, tablename=user.name),
				'commit': to_dict(row, commit.columns, tablename=commit.name)
			}), sqlconn.execute(query))
		return changes

	def query_changes_filter(self, user_id, repo_ids, filter_query, start_index_inclusive, num_results):
		assert isinstance(repo_ids, collections.Iterable)
		assert not isinstance(repo_ids, (str, unicode))

		assert isinstance(filter_query, (str, unicode))

		if not repo_ids:
			return []

		filter_query = filter_query.split()
		if not filter_query:
			return self.query_changes_group(user_id, repo_ids, "all", start_index_inclusive, num_results)

		user = database.schema.user
		change = database.schema.change
		commit = database.schema.commit
		temp_string = database.schema.temp_string

		query = change.join(commit).join(user).join(
			temp_string,
			or_(
				func.lower(temp_string.c.string) == func.lower(user.c.first_name),
				func.lower(temp_string.c.string) == func.lower(user.c.last_name),
				func.lower(commit.c.sha).startswith(func.lower(temp_string.c.string))
			)
		)

		query = query.select().apply_labels().where(
			or_(*[change.c.repo_id == repo_id for repo_id in repo_ids])
		)
		query = query.order_by(change.c.create_time.desc()).limit(num_results).offset(
			start_index_inclusive)

		with ConnectionFactory.transaction_context() as sqlconn:
			load_temp_strings(filter_query)
			changes = map(lambda row: dict(to_dict(row, change.columns, tablename=change.name), **{
				'user': to_dict(row, user.columns, tablename=user.name),
				'commit': to_dict(row, commit.columns, tablename=commit.name)
			}), sqlconn.execute(query))

		return changes

	def get_changes_between_timestamps(self, user_id, repo_ids, start_timestamp, end_timestamp=None):
		assert isinstance(repo_ids, collections.Iterable)
		assert not isinstance(repo_ids, str)

		change = database.schema.change
		temp_string = database.schema.temp_string

		query = change.join(
			temp_string,
			cast(temp_string.c.string, Integer) == change.c.repo_id
		)
		range_query = change.c.end_time > start_timestamp
		if end_timestamp is not None:
			range_query = and_(
				range_query,
				change.c.end_time < end_timestamp
			)

		query = query.select().apply_labels().where(range_query)

		with ConnectionFactory.transaction_context() as sqlconn:
			load_temp_strings(repo_ids)
			changes = map(lambda row: to_dict(row, change.columns,
				tablename=change.name), sqlconn.execute(query))
		return changes

	def get_export_uris(self, user_id, change_id):
		change_export_uri = database.schema.change_export_uri

		query = change_export_uri.select().where(change_export_uri.c.change_id == change_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			export_uris = [row[change_export_uri.c.uri] for row in sqlconn.execute(query)]
		return sorted(export_uris)

	def can_hear_change_events(self, user_id, id_to_listen_to):
		return True


class NoSuchChangeError(Exception):
	pass
