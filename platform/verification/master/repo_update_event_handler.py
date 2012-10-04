from kombu import Producer

from handler import MessageHandler
from model_server import ModelServer
from settings.model_server import repo_update_queue
from settings.verification_server import *


class RepoUpdateEventHandler(MessageHandler):
	def __init__(self):
		super(RepoUpdateEventHandler, self).__init__(repo_update_queue)

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(RepoUpdateEventHandler, self).bind(channel)

	def handle_message(self, body, message):
		commit_id, merge_target = body
		change_id = self._create_change(commit_id, merge_target)
		for commit_list in self._get_commit_permutations(commit_id):
			self._send_verification_request(change_id, commit_list)
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def _create_change(self, commit_id, merge_target):
		with ModelServer.rpc_connect("change", "create") as model_server_rpc:
			return model_server_rpc.create_change(commit_id, merge_target)

	def _get_commit_permutations(self, commit_id):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit id
		return [[commit_id]]

	def _send_verification_request(self, change_id, commit_list):
		print "Sending verification request for " + str((change_id, commit_list))
		self.producer.publish((change_id, commit_list,),
			exchange=verification_request_queue.exchange,
			routing_key=verification_request_queue.routing_key,
			delivery_mode=2,  # make message persistent
		)
