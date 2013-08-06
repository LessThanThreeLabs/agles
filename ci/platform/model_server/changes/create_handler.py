import time

import database.schema
import repo.store as repostore

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy import select
from sqlalchemy.sql import func
from util import pathgen
from util.log import Logged
from util.sql import to_dict


@Logged()
class ChangesCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesCreateHandler, self).__init__("changes", "create")

	def create_commit_and_change(self, repo_id, user_id, commit_message, sha, merge_target, store_pending=False):
		commit_id = self._create_commit(repo_id, user_id, commit_message, sha, store_pending)

		change = database.schema.change
		repo = database.schema.repo
		user = database.schema.user

		prev_change_number = 0

		create_time = int(time.time())

		with ConnectionFactory.get_sql_connection() as sqlconn:
			change_number_query = select([func.max(change.c.number)], change.c.repo_id == repo_id)
			max_change_number_result = sqlconn.execute(change_number_query).first()
			if max_change_number_result and max_change_number_result[0]:
				prev_change_number = max_change_number_result[0]
			change_number = prev_change_number + 1
			ins = change.insert().values(commit_id=commit_id, repo_id=repo_id, merge_target=merge_target,
				number=change_number, verification_status=BuildStatus.QUEUED, create_time=create_time)
			result = sqlconn.execute(ins)
			change_id = result.inserted_primary_key[0]
			repo_id_query = repo.select().where(repo.c.id == repo_id)
			repo_row = sqlconn.execute(repo_id_query).first()
			repo_id = repo_row[repo.c.id]
			repo_type = repo_row[repo.c.type]

			query = user.select().where(user.c.id == user_id)
			user_row = sqlconn.execute(query).first()

		user = to_dict(user_row, user.columns)
		self.publish_event("repos", repo_id, "change added", user=user, repo_type=repo_type, change_id=change_id, change_number=change_number,
			verification_status="queued", commit_id=commit_id, sha=sha, merge_target=merge_target, create_time=create_time)
		return {"change_id": change_id, "commit_id": commit_id}

	def _create_commit(self, repo_id, user_id, commit_message, sha, store_pending):
		commit = database.schema.commit

		timestamp = int(time.time())
		ins = commit.insert().values(repo_id=repo_id, user_id=user_id,
			message=commit_message, sha=sha, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		commit_id = result.inserted_primary_key[0]

		if store_pending:
			self._store_pending_commit(repo_id, sha, commit_id)

		self._push_pending_commit(repo_id, sha, commit_id)

		return commit_id

	def _store_pending_commit(self, repo_id, sha, commit_id):
		info = self._get_repostore_id_and_repo_name(repo_id)
		manager = repostore.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
		manager.store_pending(info['repostore_id'], repo_id, info['repo_name'], sha, commit_id)

	def _push_pending_commit(self, repo_id, sha, commit_id):
		info = self._get_repostore_id_and_repo_name(repo_id)
		manager = repostore.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))
		try:
			# Make the commit available at refs/pending/<sha>
			manager.push(info['repostore_id'], repo_id, info['repo_name'], sha, pathgen.hidden_ref(sha), force=False)
		except:
			self.logger.warn('Failed to push back pending commit', exc_info=True)

	def _get_repostore_id_and_repo_name(self, repo_id):
		schema = database.schema
		query = schema.repo.select().where(schema.repo.c.id == repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			repostore_id = row[schema.repo.c.repostore_id]
			repo_name = row[schema.repo.c.name]
		return dict(repostore_id=repostore_id, repo_name=repo_name)


class NoSuchCommitError(Exception):
	pass
