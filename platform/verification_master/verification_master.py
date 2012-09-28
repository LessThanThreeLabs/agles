import pika
import msgpack

from verification_server.verification_result import *
from settings.rabbit import connection_parameters
from settings.model_server import repo_update_routing_key
from settings.verification_server import *


class VerificationMaster(object):

	def __init__(self):
		rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.request_forwarder = rabbit_connection.channel()
		self.request_forwarder.queue_declare(queue=verification_request_queue_name)

		self.results_reporter = rabbit_connection.channel()
		self.results_reporter.queue_declare(queue=merge_queue_name)

	def run(self):
		self.listen()

	def listen(self):
		rabbit_connection = pika.BlockingConnection(connection_parameters)
		channel = rabbit_connection.channel()
		channel.basic_qos(prefetch_count=1)
		self.bind_request_listener(channel)
		self.bind_results_listener(channel)
		channel.start_consuming()

	def bind_request_listener(self, channel):
		channel.queue_declare(queue=repo_update_routing_key)
		print "Listening for new patch sets"
		channel.basic_consume(self.request_callback,
			queue=repo_update_routing_key)

	def bind_results_listener(self, channel):
		channel.queue_declare(queue=verification_results_queue_name)
		print "Listening for verification results"
		channel.basic_consume(self.results_callback,
			queue=verification_results_queue_name)

	def request_callback(self, channel, method, properties, body):
		repo_hash, sha, ref = msgpack.unpackb(body)
		for commit_list in self.get_commit_permutations(repo_hash, sha, ref):
			self.send_verification_request(repo_hash, commit_list)
		channel.basic_ack(delivery_tag=method.delivery_tag)

	def get_commit_permutations(self, repo_hash, sha, ref):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit which is a sha, ref pair
		return [[(sha, ref,)]]

	def send_verification_request(self, repo_hash, commit_list):
		print "Sending verification request for " + str((repo_hash, commit_list,))
		self.request_forwarder.basic_publish(exchange='',
			routing_key=verification_request_queue_name,
			body=msgpack.packb((repo_hash, commit_list,)),
			properties=pika.BasicProperties(
				delivery_mode=2,  # make message persistent
			))

	def results_callback(self, channel, method, properties, body):
		repo_hash, commit_list, results = msgpack.unpackb(body, use_list=True)
		self.handle_results(repo_hash, commit_list, results)
		channel.basic_ack(delivery_tag=method.delivery_tag)

	def handle_results(self, repo_hash, commit_list, results):
		# TODO (bbland): do something more useful than this trivial case
		if len(commit_list) == 1 and results == VerificationResult.SUCCESS:
			sha, ref = commit_list[0]
			self.send_merge_request(repo_hash, sha, ref)

	def send_merge_request(self, repo_hash, sha, ref):
		print "Sending merge request for " + str((repo_hash, sha, ref,))
		self.results_reporter.basic_publish(exchange='',
			routing_key=merge_queue_name,  # TODO (bbland): replace with something useful
			body=msgpack.packb((repo_hash, sha, ref,)),
			properties=pika.BasicProperties(
				delivery_mode=2,  # make message persistent
			))
