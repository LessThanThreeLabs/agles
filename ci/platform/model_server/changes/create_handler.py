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

	def create_commit_and_change(self, repo_hash, user_id, commit_message, merge_target):
		commit_id = self._create_commit(repo_hash, user_id, commit_message)

		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo

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
			ins = change.insert().values(commit_id=commit_id, merge_target=merge_target,
				number=change_number, status=BuildStatus.QUEUED)
			result = sqlconn.execute(ins)
			change_id = result.inserted_primary_key[0]
			repo_id_query = repo.select().where(repo.c.hash==repo_hash)
			repo_id = sqlconn.execute(repo_id_query).first()[repo.c.hash]
		self.publish_event("repos", repo_id, "change added", change_id=change_id, change_number=change_number,
			commit_id=commit_id, merge_target=merge_target)
		return {"change_id": change_id, "commit_id": commit_id}

	def _create_commit(self, repo_hash, user_id, commit_message):
		commit = database.schema.commit

		timestamp = int(time.time())
		ins = commit.insert().values(repo_hash=repo_hash, user_id=user_id,
			message=commit_message, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		commit_id = result.inserted_primary_key[0]
		return commit_id


class NoSuchCommitError(Exception):
	pass
