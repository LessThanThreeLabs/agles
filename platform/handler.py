# handler.py - Implementation of message handlers
""" Contains implementation of various message
"""
import msgpack
import zerorpc

from kombu import Consumer

from repo.store import DistributedLoadBalancingRemoteRepositoryManager, MergeError
from settings.rabbit import connection_parameters


class MessageHandler(object):
	def __init__(self, queue):
		self.queue = queue

	def bind(self, channel):
		Consumer(channel, queues=self.queue, callbacks=[self.handle_message]).consume()

	def handle_message(self, body, message):
		raise NotImplementedError("Subclasses should override this!")


class VerificationResultHandler(MessageHandler):
	"""Handles merge messages from verification servers requesting for merges.
	Takes a message, attempts to merge the requested change, and marks the
	commit as merged/failed in the database
	"""

	def __init__(self, model_server_address):
		self.model_server_address = model_server_address
		self.rabbit_connection = pika.BlockingConnection(connection_parameters)
		self.remote_repo_manager = DistributedLoadBalancingRemoteRepositoryManager.create_from_settings()

	def _merge_change(self, channel, method, repo_hash, repo_name,
                      ref_to_merge, ref_to_merge_into):
		client = zerorpc.Client(self.model_server_address)
		filesystem_server_uri = client.get_filesystem_server_uri(repo_hash)
		client.close()
		merge_status = True
		try:
			self.remote_repo_manager.merge_changeset(
                filesystem_server_uri, repo_name,
                ref_to_merge, ref_to_merge_into)
		except MergeError:
			merge_status = False
		client = zerorpc.Client(self.model_server_address)
		client.mark_merge(merge_status)
		client.close()

	def handle_message(self, channel, method, properties, body):
		repo_hash, ref_to_merge, ref_to_merge_into, verification_result = msgpack.unpackb(body)
		client = zerorpc.Client(self.model_server_address)
		repo_name = client.get_repo_name(repo_hash)
		client.mark_verification(verification_result)
		client.close()
		if verification_result:
			self._merge_change(channel, method, repo_hash, repo_name,
                ref_to_merge, ref_to_merge_into)
		channel.basic_ack(delivery_tag=method.delivery_tag)
