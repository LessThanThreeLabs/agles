from kombu import Producer

from shared.constants import BuildStatus
from shared.handler import QueueListener
from model_server import ModelServer
from model_server.build.update_handler import Console
from settings.verification_server import *
from util import pathgen
from verification_result import VerificationResult


class VerificationRequestHandler(QueueListener):
	"""Handles verification requests sent from verification masters
	and triggers a Verify on the commit list.
	"""
	def __init__(self, verifier):
		super(VerificationRequestHandler, self).__init__(verification_request_queue)
		self.verifier = verifier

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(VerificationRequestHandler, self).bind(channel)

	def handle_message(self, body, message):
		"""Respond to a verification event, begin verifying"""
		build_id = body
		commit_list = self._get_commit_list(build_id)
		print "Processing verification request: " + str((build_id, commit_list,))
		self._start_build(build_id)
		repo_uri = self.get_repo_uri(commit_list[0])
		refs = self._get_ref_list(commit_list)
		with ModelServer.rpc_connect("build", "update") as model_server_rpc:
			console_appender = self._make_console_appender(model_server_rpc, build_id)
			verify_callback = self.make_verify_callback(build_id, model_server_rpc, message)
			self.verifier.verify(repo_uri, refs, verify_callback, console_appender=console_appender)

	def _get_commit_list(self, build_id):
		with ModelServer.rpc_connect("build", "read") as model_server_rpc:
			return model_server_rpc.get_commit_list(build_id)

	def _get_ref_list(self, commit_list):
		return [pathgen.hidden_ref(commit) for commit in commit_list]

	def _start_build(self, build_id):
		with ModelServer.rpc_connect("build", "update") as model_server_rpc:
			model_server_rpc.start_build(build_id)

	def make_verify_callback(self, build_id, model_server_rpc, message):
		"""Returns the default callback function to be
		called with a return value after verification.
		Sends a message denoting the return value and acks"""
		def default_verify_callback(results):
			self.producer.publish((build_id, results),
				exchange=verification_results_queue.exchange,
				routing_key=verification_results_queue.routing_key,
				delivery_mode=2,  # make message persistent
			)
			model_server_rpc.flush_console_output(build_id, Console.Setup)
			status = BuildStatus.COMPLETE if results == VerificationResult.SUCCESS else BuildStatus.FAILED
			model_server_rpc.mark_build_finished(build_id, status)
			message.channel.basic_ack(delivery_tag=message.delivery_tag)
		return default_verify_callback

	def get_repo_uri(self, commit_id):
		"""Sends out a rpc call to the model server to retrieve
		the uri of a repository for a commit"""
		with ModelServer.rpc_connect("repo", "read") as model_server_rpc:
			return model_server_rpc.get_repo_uri(commit_id)

	def _make_console_appender(self, model_server_rpc, build_id):
		def console_appender(console):
			return lambda line: model_server_rpc.append_console_output(build_id, line, console)
		return console_appender
