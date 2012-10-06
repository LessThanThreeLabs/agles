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
		repo_hash, commit_list, results = body
		self.handle_results(repo_hash, commit_list, results)
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def handle_results(self, repo_hash, commit_list, results):
		# TODO (bbland): do something more useful than this trivial case
		if len(commit_list) == 1 and results == VerificationResult.SUCCESS:
			ref, parent_ref = commit_list[0]
			self.send_merge_request(repo_hash, ref, parent_ref)

	def send_merge_request(self, repo_hash, ref, parent_ref):
		print "Sending merge request for " + str((repo_hash, ref, parent_ref,))
		with ModelServer.rpc_connect("repo", "read") as client:
			repo_uri = client.get_repo_address(repo_hash)
			print "Repo uri: " + repo_uri
			filesystem_server_uri, repo_hash, repo_name = client.get_repo_attributes(repo_uri)
		print "Machine uri: " + filesystem_server_uri
		try:
			self.remote_repo_manager.merge_changeset(
                filesystem_server_uri, repo_hash,
                repo_name, ref, parent_ref)
		except MergeError:
			merge_status = False
		"""
		with ModelServer.rpc_connect("repo", "update") as client:
					client.mark_merge(merge_status)
		"""

		self.producer.publish((repo_hash, ref, parent_ref,),
			exchange=merge_queue.exchange,
			routing_key=merge_queue.routing_key,  # TODO (bbland): replace with something useful
			delivery_mode=2,  # make message persistent
		)
