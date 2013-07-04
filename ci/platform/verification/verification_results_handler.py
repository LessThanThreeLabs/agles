import model_server

from database.engine import ConnectionFactory
from repo.store import DistributedLoadBalancingRemoteRepositoryManager, MergeError, PushForwardError
from shared.constants import BuildStatus, MergeStatus
from util import pathgen
from util.log import Logged


@Logged()
class VerificationResultsHandler(object):
	def __init__(self):
		self.remote_repo_manager = DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection('repostore'))

	def pass_change(self, change_id):
		merge_success = self._send_merge_request(change_id, BuildStatus.PASSED)
		if merge_success:
			self._set_change_status_if_not_finished(change_id, BuildStatus.PASSED, MergeStatus.PASSED)

	def skip_change(self, change_id):
		merge_success = self._send_merge_request(change_id, BuildStatus.SKIPPED)
		if merge_success:
			self._set_change_status_if_not_finished(change_id, BuildStatus.SKIPPED, MergeStatus.PASSED)

	def fail_change(self, change_id):
		self.logger.info("Failing change %d" % change_id)
		self._set_change_status_if_not_finished(change_id, BuildStatus.FAILED)

	def _mark_change_merge_failure(self, change_id, verification_status):
		self._set_change_status_if_not_finished(change_id, verification_status, MergeStatus.FAILED)

	def _mark_change_pushforward_failure(self, change_id, verification_status):
		self._set_change_status_if_not_finished(change_id, verification_status, MergeStatus.FAILED)

	def _send_merge_request(self, change_id, verification_status):
		self.logger.info("Sending merge request for change %d" % change_id)
		with model_server.rpc_connect("changes", "read") as client:
			change_attributes = client.get_change_attributes(change_id)

		commit_id = change_attributes['commit_id']
		merge_target = change_attributes['merge_target']

		# TODO(andrey) make this work for Hg
		if merge_target == 'verify only':
			return True

		with model_server.rpc_connect("repos", "read") as client:
			repo_uri = client.get_repo_uri(commit_id)
			repostore_id, route, repos_path, repo_id, repo_name, repo_type = client.get_repo_attributes(repo_uri)

		ref = pathgen.hidden_ref(commit_id)
		try:
			self.remote_repo_manager.merge_changeset(
				repostore_id, repo_id,
				repo_name, ref, merge_target)
			return True
		except MergeError:
			self._mark_change_merge_failure(change_id, verification_status)
			self.logger.info("Failed to merge change %d" % change_id, exc_info=True)
		except PushForwardError:
			self._mark_change_pushforward_failure(change_id, verification_status)
			self.logger.warn("Failed to forward push change %d" % change_id, exc_info=True)
		except:
			self._mark_change_merge_failure(change_id, verification_status)
			self.logger.error("Failed to merge/push change %d" % change_id, exc_info=True)
		return False

	def _set_change_status_if_not_finished(self, change_id, verification_status, merge_status=None):
		with model_server.rpc_connect("changes", "read") as changes_read_rpc:
			existing_verification_status = changes_read_rpc.get_change_attributes(change_id)['verification_status']
		if existing_verification_status not in (BuildStatus.PASSED, BuildStatus.FAILED, BuildStatus.SKIPPED):
			with model_server.rpc_connect("changes", "update") as changes_update_rpc:
				changes_update_rpc.mark_change_finished(change_id, verification_status, merge_status)
