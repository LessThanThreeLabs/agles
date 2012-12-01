from kombu.messaging import Producer

from shared.handler import EventSubscriber
from model_server import ModelServer
from settings.verification_server import *


class ChangesCreateEventHandler(EventSubscriber):
	def __init__(self):
		super(ChangesCreateEventHandler, self).__init__("changes", "verification_master:repos.update")

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(ChangesCreateEventHandler, self).bind(channel)

	def handle_message(self, body, message):
		try:
			if body["name"] == "change created":
				self._handle_new_change(body["contents"])
				message.channel.basic_ack(delivery_tag=message.delivery_tag)
		except Exception as e:
			message.channel.basic_reject(delivery_tag=message.delivery_tag, requeue=True)
			print e  # Should log this

	def _handle_new_change(self, contents):
		change_id = contents["change_id"]
		for commit_list in self._get_commit_permutations(change_id):
			build_id = self._create_build(change_id, commit_list)
			self._send_verification_request(build_id)

	def _get_commit_id(self, change_id):
		with ModelServer.rpc_connect("changes", "read") as model_server_rpc:
			return model_server_rpc.get_change_attributes(change_id)[0]

	def _create_build(self, change_id, commit_list):
		with ModelServer.rpc_connect("builds", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id, commit_list)

	def _get_commit_permutations(self, change_id):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit id
		return [[self._get_commit_id(change_id)]]

	def _send_verification_request(self, build_id):
		print "Sending verification request for " + str(build_id)
		self.producer.publish(build_id,
			exchange=verification_request_queue.exchange,
			routing_key=verification_request_queue.routing_key,
			delivery_mode=2,  # make message persistent
			mandatory=True,
		)
