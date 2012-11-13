from kombu.messaging import Producer

from shared.constants import BuildStatus
from database.engine import ConnectionFactory
from shared.handler import QueueListener
from model_server import ModelServer
from repo.store import DistributedLoadBalancingRemoteRepositoryManager, MergeError
from settings.verification_server import *
from util import pathgen
from verification.server.verification_result import VerificationResult


class VerificationResultsHandler(QueueListener):
	def __init__(self):
		super(VerificationResultsHandler, self).__init__(verification_results_queue)
		self.remote_repo_manager = DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(VerificationResultsHandler, self).bind(channel)

	def handle_message(self, body, message):
		build_id, results = body
		self.handle_results(build_id, results)
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def handle_results(self, build_id, results):
		# TODO (bbland): do something more useful than this trivial case
		with ModelServer.rpc_connect("builds", "read") as client:
			build = client.get_build_from_id(build_id)
		if build["is_primary"]:
			if results == VerificationResult.SUCCESS:
				self._mark_change_finished(build["change_id"])
			else:
				self._mark_change_failed(build["change_id"])

	def _mark_change_finished(self, change_id):
		with ModelServer.rpc_connect("changes", "update") as client:
			client.mark_change_finished(change_id, BuildStatus.COMPLETE)
		self.send_merge_request(change_id)

	def _mark_change_failed(self, change_id):
		with ModelServer.rpc_connect("changes", "update") as client:
			client.mark_change_finished(change_id, BuildStatus.FAILED)

	def send_merge_request(self, change_id):
		print "Sending merge request for " + str(change_id)
		with ModelServer.rpc_connect("changes", "read") as client:
			change_attributes = client.get_change_attributes(change_id)
		commit_id = change_attributes[0]
		merge_target = change_attributes[1]

		with ModelServer.rpc_connect("repos", "read") as client:
			repo_uri = client.get_repo_uri(commit_id)
			machine_uri, route, repos_path, repo_hash, repo_name = client.get_repo_attributes(repo_uri)

		ref = pathgen.hidden_ref(commit_id)
		try:
			self.remote_repo_manager.merge_changeset(
                machine_uri, repo_hash,
                repo_name, ref, merge_target)
		except MergeError:
			merge_status = False
		"""
		with ModelServer.rpc_connect("repos", "update") as client:
					client.mark_merge(merge_status)
		"""
		self.producer.publish((repo_hash, commit_id, merge_target,),
			exchange=merge_queue.exchange,
			routing_key=merge_queue.routing_key,  # TODO (bbland): replace with something useful
			delivery_mode=2,  # make message persistent
		)
