# handler.py - Implementation of message handlers
""" Contains implementation of various message
"""
import msgpack
import pika
import zerorpc

from repo.store import DistributedLoadBalancingRemoteRepositoryManager, MergeError

from settings.rabbit import connection_parameters
from settings.verification_server import verification_results_queue_name


class MessageHandler(object):
	def run(self):
		raise NotImplementedError("Subclasses should override this!")

	def listen(self, request_listener, queue):
		request_listener.queue_declare(queue=verification_results_queue_name, durable=True)
		request_listener.basic_qos(prefetch_count=1)

		print "Listening for requests"

		request_listener.basic_consume(self.handle_message,
				queue=verification_results_queue_name)
		request_listener.start_consuming()

	def handle_message(self, channel, method, properties, body):
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

	def run(self):
		request_listener = self.rabbit_connection.channel()
		self.listen(request_listener, verification_results_queue_name)

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
