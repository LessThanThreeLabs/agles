import logging

from kombu.messaging import Producer

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from shared.handler import QueueListener
from model_server import ModelServer
from repo.store import DistributedLoadBalancingRemoteRepositoryManager, MergeError, PushForwardError
from settings.verification_server import VerificationServerSettings
from util import pathgen


class VerificationResultsHandler(QueueListener):
	logger = logging.getLogger("FileSystemRepositoryStore")

	def __init__(self):
		super(VerificationResultsHandler, self).__init__(VerificationServerSettings.verification_results_queue)
		self.remote_repo_manager = DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(VerificationResultsHandler, self).bind(channel)

	def handle_message(self, body, message):
		build_id, status = body['build_id'], body['status']
		try:
			self.handle_results(build_id, status)
		except:
			self.logger.error("Failed to handle verification results %s" % body, exc_info=True)
		finally:
			message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def handle_results(self, build_id, status):
		# TODO (bbland): do something more useful than this trivial case
		with ModelServer.rpc_connect("builds", "read") as client:
			build = client.get_build_from_id(build_id)
		with ModelServer.rpc_connect("changes", "read") as client:
			builds = client.get_builds_from_change_id(build["change_id"])
		success = all(map(lambda build: build["status"] == BuildStatus.PASSED, builds))
		failure = any(map(lambda build: build["status"] == BuildStatus.FAILED, builds))
		if success:
			self._mark_change_finished(build["change_id"])
		elif failure:
			self._mark_change_failed(build["change_id"])
		else:
			self.logger.debug("Still waiting for more results to finish build %s" % build_id)

	def _mark_change_finished(self, change_id):
		merge_success = self.send_merge_request(change_id)
		if merge_success:
			with ModelServer.rpc_connect("changes", "update") as client:
				client.mark_change_finished(change_id, BuildStatus.PASSED)

	def _mark_change_failed(self, change_id):
		with ModelServer.rpc_connect("changes", "update") as client:
			client.mark_change_finished(change_id, BuildStatus.FAILED)

	def _mark_change_merge_failure(self, change_id):
		with ModelServer.rpc_connect("changes", "update") as client:
			client.mark_change_finished(change_id, BuildStatus.FAILED_TO_MERGE)

	def _mark_change_pushforward_failure(self, change_id):
		with ModelServer.rpc_connect("changes", "update") as client:
			client.mark_change_finished(change_id, BuildStatus.FAILED_TO_MERGE)

	def send_merge_request(self, change_id):
		self.logger.info("Sending merge request for change %s" % change_id)
		with ModelServer.rpc_connect("changes", "read") as client:
			change_attributes = client.get_change_attributes(change_id)
		commit_id = change_attributes[0]
		merge_target = change_attributes[1]

		with ModelServer.rpc_connect("repos", "read") as client:
			repo_uri = client.get_repo_uri(commit_id)
			repostore_id, route, repos_path, repo_id, repo_name, private_key = client.get_repo_attributes(repo_uri)

		ref = pathgen.hidden_ref(commit_id)
		try:
			self.remote_repo_manager.merge_changeset(
				repostore_id, repo_id,
				repo_name, ref, merge_target)
			return True
		except MergeError:
			self._mark_change_merge_failure(change_id)
			self.logger.info("Failed to merge change %s" % change_id, exc_info=True)
		except PushForwardError:
			self._mark_change_pushforward_failure(change_id)
			self.logger.warn("Failed to forward push change %s" % change_id, exc_info=True)
		except:
			self._mark_change_failed(change_id)
			self.logger.error("Failed to merge/push change %s" % change_id, exc_info=True)
		return False
