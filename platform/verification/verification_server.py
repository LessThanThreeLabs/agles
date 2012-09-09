import pika
import zerorpc
import msgpack

from threading import Thread
from settings import verification_server


class VerificationServer(object):
	"""Manages and routes requests for verification of builds"""

	DEFAULT_RPC_TIMEOUT = 500

	@classmethod
	def get_connection(cls):
		return zerorpc.Client(verification_server.bind_address, timeout=cls.DEFAULT_RPC_TIMEOUT)

	def __init__(self):
		connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
		self.request_forwarder = connection.channel()

		self.request_forwarder.queue_declare(queue='task_queue', durable=True)

	def verify(self, repo_hash, sha, ref):
		# spawns verify event
		Thread(target=self.verify_event, args=(repo_hash, sha, ref)).start()

	def verify_event(self, repo_hash, sha, ref):
		# get committer and user, write into db the repo, sha, ref, etc
		repo_address = self.get_repo_address(repo_hash)
		self.request_forwarder.basic_publish(exchange='',
			routing_key='task_queue',
			body=msgpack.packb([repo_address, sha]),
			properties=pika.BasicProperties(
				delivery_mode=2,  # make message persistent
			))

	def get_repo_address(self, repo_hash):
		# get the repo address from the db/repo server
		return "git://sample.address.git"
