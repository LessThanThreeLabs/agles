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
			build_id = self._create_build(change_id, commit_list)
			self._send_verification_request(build_id)
		message.channel.basic_ack(delivery_tag=message.delivery_tag)

	def _create_change(self, commit_id, merge_target):
		with ModelServer.rpc_connect("change", "create") as model_server_rpc:
			return model_server_rpc.create_change(commit_id, merge_target)

	def _create_build(self, change_id, commit_list):
		with ModelServer.rpc_connect("build", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id, commit_list)

	def _get_commit_permutations(self, commit_id):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit id
		return [[commit_id]]

	def _send_verification_request(self, build_id):
		print "Sending verification request for " + str(build_id)
		self.producer.publish(build_id,
			exchange=verification_request_queue.exchange,
			routing_key=verification_request_queue.routing_key,
			delivery_mode=2,  # make message persistent
		)
