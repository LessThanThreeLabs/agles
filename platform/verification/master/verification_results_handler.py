from kombu import Producer

from handler import MessageHandler
from model_server import ModelServer
from repo.store import DistributedLoadBalancingRemoteRepositoryManager, MergeError
from settings.verification_server import *
from verification.server.verification_result import VerificationResult


class VerificationResultsHandler(MessageHandler):
	def __init__(self):
		super(VerificationResultsHandler, self).__init__(verification_results_queue)
		self.remote_repo_manager = DistributedLoadBalancingRemoteRepositoryManager.create_from_settings()

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(VerificationResultsHandler, self).bind(channel)

	def handle_message(self, body, message):
		change_id, commit_list, results = body
		self.handle_results(change_id, commit_list, results)
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def handle_results(self, change_id, commit_list, results):
		# TODO (bbland): do something more useful than this trivial case
		if len(commit_list) == 1 and results == VerificationResult.SUCCESS:
			self.send_merge_request(change_id)

	def send_merge_request(self, change_id):
		print "Sending merge request for " + str(change_id)
		with ModelServer.rpc_connect("change", "read") as client:
			change_attributes = client.get_change_attributes(change_id)
		commit_id = change_attributes[0]
		merge_target = change_attributes[1]

		with ModelServer.rpc_connect("repo", "read") as client:
			user_id, repo_id, ref, message, timestamp = client.get_commit_attributes(commit_id)
			repo_uri = client.get_repo_uri(commit_id)
			filesystem_server_uri, repo_hash, repo_name = client.get_repo_attributes(repo_uri)

		try:
			self.remote_repo_manager.merge_changeset(
                filesystem_server_uri, repo_hash,
                repo_name, ref, merge_target)
		except MergeError:
			merge_status = False
		"""
		with ModelServer.rpc_connect("repo", "update") as client:
					client.mark_merge(merge_status)
		"""

		self.producer.publish((repo_hash, ref, merge_target,),
			exchange=merge_queue.exchange,
			routing_key=merge_queue.routing_key,  # TODO (bbland): replace with something useful
			delivery_mode=2,  # make message persistent
		)
