import msgpack

from kombu import Producer

from handler import MessageHandler
from settings.verification_server import *
from verification.server.verification_result import VerificationResult


class VerificationResultsHandler(MessageHandler):
	def __init__(self):
		super(VerificationResultsHandler, self).__init__(verification_results_queue)

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
			sha, ref = commit_list[0]
			self.send_merge_request(repo_hash, sha, ref)

	def send_merge_request(self, repo_hash, sha, ref):
		print "Sending merge request for " + str((repo_hash, sha, ref,))
		self.producer.publish((repo_hash, sha, ref,),
			exchange=merge_queue.exchange,
			routing_key=merge_queue.routing_key,  # TODO (bbland): replace with something useful
			delivery_mode=2,  # make message persistent
		)
