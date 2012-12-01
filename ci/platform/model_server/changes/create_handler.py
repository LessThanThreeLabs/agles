import time

import database.schema

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy import select
from sqlalchemy.sql import func


class ChangesCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesCreateHandler, self).__init__("changes", "create")

	def create_change(self, commit_id, merge_target):
		change = database.schema.change
		commit = database.schema.commit

		prev_change_number = 0

		repo_hash_query = commit.select().where(commit.c.id==commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			commit_result = sqlconn.execute(repo_hash_query).first()
			if not commit_result:
				raise NoSuchCommitError(commit_id)
			repo_hash = commit_result[commit.c.repo_hash]
			change_number_query = select([func.max(change.c.number)], commit.c.repo_hash==repo_hash, [change, commit])
			max_change_number_result = sqlconn.execute(change_number_query).first()
			if max_change_number_result and max_change_number_result[0]:
				prev_change_number = max_change_number_result[0]
			change_number = prev_change_number + 1
			start_time = int(time.time())
			ins = change.insert().values(commit_id=commit_id, merge_target=merge_target,
				number=change_number, status=BuildStatus.QUEUED, start_time=start_time)
			result = sqlconn.execute(ins)
		change_id = result.inserted_primary_key[0]
		self.publish_event(change_id=change_id, change_number=change_number,
			commit_id=commit_id, merge_target=merge_target, start_time=start_time)
		return change_id


class NoSuchCommitError(Exception):
	pass
