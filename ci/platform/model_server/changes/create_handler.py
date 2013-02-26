import time

import database.schema

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy import select
from sqlalchemy.sql import func
from util.sql import to_dict


class ChangesCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesCreateHandler, self).__init__("changes", "create")

	def create_commit_and_change(self, repo_id, user_id, commit_message, sha, merge_target):
		commit_id = self._create_commit(repo_id, user_id, commit_message, sha)

		change = database.schema.change
		repo = database.schema.repo
		user = database.schema.user

		prev_change_number = 0

		with ConnectionFactory.get_sql_connection() as sqlconn:
			change_number_query = select([func.max(change.c.number)], change.c.repo_id == repo_id)
			max_change_number_result = sqlconn.execute(change_number_query).first()
			if max_change_number_result and max_change_number_result[0]:
				prev_change_number = max_change_number_result[0]
			change_number = prev_change_number + 1
			ins = change.insert().values(commit_id=commit_id, repo_id=repo_id, merge_target=merge_target,
				number=change_number, status=BuildStatus.QUEUED)
			result = sqlconn.execute(ins)
			change_id = result.inserted_primary_key[0]
			repo_id_query = repo.select().where(repo.c.id == repo_id)
			repo_id = sqlconn.execute(repo_id_query).first()[repo.c.id]

			query = user.select().where(user.c.id == user_id)
			user_row = sqlconn.execute(query).first()

		user = to_dict(user_row, user.columns)
		self.publish_event("repos", repo_id, "change added", user=user, change_id=change_id, change_number=change_number,
			change_status="queued", commit_id=commit_id, merge_target=merge_target)
		return {"change_id": change_id, "commit_id": commit_id}

	def _create_commit(self, repo_id, user_id, commit_message, sha):
		commit = database.schema.commit

		timestamp = int(time.time())
		ins = commit.insert().values(repo_id=repo_id, user_id=user_id,
			message=commit_message, sha=sha, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		commit_id = result.inserted_primary_key[0]
		return commit_id


class NoSuchCommitError(Exception):
	pass
