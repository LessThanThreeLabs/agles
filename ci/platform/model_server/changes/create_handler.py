import time

import database.schema
import repo.store as repostore

from sqlalchemy import and_
from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from sqlalchemy import select
from sqlalchemy.sql import func
from util import pathgen
from util.log import Logged
from util.sql import to_dict
from repo.store import DistributedLoadBalancingRemoteRepositoryManager

# Debug instance default timeout is 50 minutes (less than one hour with boot)
DEFAULT_TIMEOUT = 50*60

@Logged()
class ChangesCreateHandler(ModelServerRpcHandler):
	def __init__(self, channel=None):
		super(ChangesCreateHandler, self).__init__("changes", "create", channel)

	def create_commit_and_change(self, repo_id, user_id, base_sha, head_sha, merge_target, verify_only=False, store_pending=False, patch_contents=None):
		repo_id = int(repo_id)
		user_id = int(user_id)

		change = database.schema.change
		repo = database.schema.repo
		user = database.schema.user
		commit = database.schema.commit

		manager = DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))

		with ConnectionFactory.get_sql_connection() as sqlconn:
			repo_type_query = repo.select().where(repo.c.id == repo_id)
			repo_row = sqlconn.execute(repo_type_query).first()
			repo_type = repo_row[repo.c.type]
			repostore_id = repo_row[repo.c.repostore_id]
			repo_name = repo_row[repo.c.name]

		commit_attributes = manager.get_commit_attributes(repostore_id, repo_id, repo_name, head_sha)

		commit_id = self._create_commit(repo_id, user_id, commit_attributes, base_sha, head_sha, store_pending)

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


			query = user.select().where(user.c.id == user_id)
			user_row = sqlconn.execute(query).first()

			# Yes, it's silly to select after inserting this
			query = commit.select().where(commit.c.id == commit_id)
			commit_row = sqlconn.execute(query).first()

		user_dict = to_dict(user_row, user.columns)
		commit_dict = to_dict(commit_row, commit.columns)
		patch_id = self.store_patch(change_id, patch_contents) if patch_contents else None

		skip = False

		if '[ci skip]' in commit_attributes['message']:
			skip = True
		elif '[ci test_only]' in commit_attributes['message']:
			verify_only = True

		self.publish_event("repos", repo_id, "change added", user=user_dict, commit=commit_dict,
			repo_type=repo_type, change_id=change_id, change_number=change_number, verification_status="queued",
			merge_target=merge_target, create_time=create_time, patch_id=patch_id, verify_only=verify_only, skip=skip)
		return {"change_id": change_id, "commit_id": commit_id}

	def create_github_commit_and_change(self, user_id, github_owner_name, github_repo_name, base_sha, head_sha, branch_name):
		github_repo_metadata = database.schema.github_repo_metadata
		repo = database.schema.repo

		with ConnectionFactory.get_sql_connection() as sqlconn:
			query = github_repo_metadata.join(repo).select().apply_labels().where(
				and_(
					repo.c.deleted == 0,
					github_repo_metadata.c.repo_name == github_repo_name,
					github_repo_metadata.c.owner_name == github_owner_name,
				)
			)
			row = sqlconn.execute(query).first()
			if row is not None:
				repo_id = row[repo.c.id]
			else:
				raise RepositoryNotFoundError(github_repo_name, github_owner_name)

		verify_only = True
		return self.create_commit_and_change(repo_id, user_id, base_sha, head_sha, branch_name, verify_only)

	def launch_debug_instance(self, user_id, change_id, timeout=DEFAULT_TIMEOUT):
		if not isinstance(timeout, (int, float)) or timeout < 0:
			timeout = DEFAULT_TIMEOUT
		self.publish_event("changes", change_id, "launch debug machine", user_id=user_id, change_id=change_id, timeout=timeout)

	def store_patch(self, change_id, patch_contents):
		patch = database.schema.patch

		with ConnectionFactory.get_sql_connection() as sqlconn:
			ins = patch.insert().values(change_id=change_id, contents=patch_contents)
			result = sqlconn.execute(ins)
			patch_id = result.inserted_primary_key[0]
		return patch_id

	def _create_commit(self, repo_id, user_id, commit_attributes, base_sha, head_sha, store_pending):
		commit = database.schema.commit

		timestamp = int(time.time())
		ins = commit.insert().values(repo_id=repo_id, user_id=user_id,
			message=commit_attributes['message'], sha=head_sha, base_sha=base_sha, timestamp=timestamp,
			committer_name=commit_attributes['username'], committer_email=commit_attributes['email'])
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(ins)
		commit_id = result.inserted_primary_key[0]

		if store_pending:
			self._store_pending_commit(repo_id, head_sha, commit_id)

		self._push_pending_commit(repo_id, head_sha, commit_id)

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


class RepositoryNotFoundError(Exception):
	pass
