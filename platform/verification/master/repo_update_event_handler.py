from kombu import Producer

from handler import MessageHandler
from settings.model_server import repo_update_queue
from settings.verification_server import *


class RepoUpdateEventHandler(MessageHandler):
	def __init__(self):
		super(RepoUpdateEventHandler, self).__init__(repo_update_queue)

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(RepoUpdateEventHandler, self).bind(channel)

	def handle_message(self, body, message):
		repo_hash, ref, parent_ref = body
		for commit_list in self.get_commit_permutations(repo_hash, ref, parent_ref):
			self.send_verification_request(repo_hash, commit_list)
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def get_commit_permutations(self, repo_hash, ref, parent_ref):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit which is a sha, ref pair
		return [[(ref, parent_ref,)]]

	def send_verification_request(self, repo_hash, commit_list):
		print "Sending verification request for " + str((repo_hash, commit_list,))
		self.producer.publish((repo_hash, commit_list,),
			exchange=verification_request_queue.exchange,
			routing_key=verification_request_queue.routing_key,
			delivery_mode=2,  # make message persistent
		)
