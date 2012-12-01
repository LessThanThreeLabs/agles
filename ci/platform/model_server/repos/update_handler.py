import time

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ReposUpdateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposUpdateHandler, self).__init__("repos", "update")

	def mark_pending_commit_and_merge_target(self, repo_hash, user_id, commit_message, merge_target):
		commit = database.schema.commit

		timestamp = int(time.time())
		ins = commit.insert().values(repo_hash=repo_hash, user_id=user_id,
			message=commit_message, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		commit_id = result.inserted_primary_key[0]

		self.publish_event(repo_hash=repo_hash, user_id=user_id, commit_id=commit_id,
			commit_message=commit_message, merge_target=merge_target, timestamp=timestamp)
		return commit_id
