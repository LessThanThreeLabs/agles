import time

import database.schema

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from kombu.connection import Connection
from model_server.events_broker import EventsBroker
from model_server.rpc_handler import ModelServerRpcHandler
from settings.rabbit import connection_info
from sqlalchemy import select
from sqlalchemy.sql import func


class ChangesCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesCreateHandler, self).__init__("changes", "create")

	def mark_pending_commit_and_merge_target(self, repo_hash, user_id, commit_message, merge_target):
		commit = database.schema.commit

		timestamp = int(time.time())
		ins = commit.insert().values(repo_hash=repo_hash, user_id=user_id,
			message=commit_message, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		commit_id = result.inserted_primary_key[0]

		with Connection(connection_info) as connection:
			events_broker = EventsBroker(connection)
			events_broker.publish(events_broker.get_event("repos", "update"), (commit_id, merge_target))
		return commit_id

	def create_change(self, commit_id, merge_target):
		change = database.schema.change
		commit = database.schema.commit

		prev_change_number = 0

		repo_hash_query = commit.select().where(commit.c.id==commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			commit_result = sqlconn.execute(repo_hash_query).first()
			if commit_result:
				repo_hash = commit_result[commit.c.repo_hash]
				change_number_query = select([func.max(change.c.number)], commit.c.repo_hash==repo_hash, [change, commit])
				max_change_number_result = sqlconn.execute(change_number_query).first()
				if max_change_number_result and max_change_number_result[0]:
					prev_change_number = max_change_number_result[0]
			change_number = prev_change_number + 1
			ins = change.insert().values(commit_id=commit_id, merge_target=merge_target,
				number=change_number, status=BuildStatus.QUEUED)
			result = sqlconn.execute(ins)
		return result.inserted_primary_key[0]
