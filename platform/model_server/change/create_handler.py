import database.schema

from constants import BuildStatus
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy.sql import func


class ChangeCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangeCreateHandler, self).__init__("change", "create")

	def create_change(self, commit_id, merge_target):
		change = database.schema.change
		commit = database.schema.commit

		prev_change_number = 0

		repo_id_query = commit.select().where(id==commit_id)
		results = self._db_conn.execute(repo_id_query).first()
		if results:
			repo_id = results[commit.c.repo_id]
			change_number_query = func.max(change.number).join(commit).filter(repo_id==repo_id)
			results = self._db_conn.execute(change_number_query).first()
			if results:
				prev_change_number = results[change.c.number]
		change_number = prev_change_number + 1
		ins = change.insert().values(commit_id=commit_id, merge_target=merge_target,
			number=change_number, status=BuildStatus.QUEUED)
		result = self._db_conn.execute(ins)
		return result.inserted_primary_key[0]
