import os
import socket
import yaml

from kombu.connection import Connection

from model_server import ModelServer
from model_server.build_consoles import ConsoleType
from settings.rabbit import RabbitSettings
from settings.verification_server import VerificationServerSettings
from shared.constants import BuildStatus, VerificationUser
from util import pathgen
from task_queue.task_worker import InfiniteWorker
from virtual_machine.remote_command import SimpleRemoteTestCommand
from verification.shared.pubkey_registrar import PubkeyRegistrar
from verification.shared.verification_config import VerificationConfig


class VerificationRequestHandler(InfiniteWorker):
	"""Handles verification requests sent from verification masters
	and triggers a Verify on the commit list.
	"""
	def __init__(self, verifier):
		self.verifier = verifier
		super(VerificationRequestHandler, self).__init__(VerificationServerSettings.verification_worker_queue)
		self._check_for_interrupted_build()
		self._register_pubkey()

	def _register_pubkey(self):
		PubkeyRegistrar().register_pubkey(VerificationUser.id, self.worker_id)

	def _get_vm_directory(self):
		return os.path.abspath(self.verifier.virtual_machine.vm_directory)

	def _get_build_info_file(self):
		return os.path.abspath(os.path.join(self._get_vm_directory(), '.build'))

	def get_worker_id(self):
		return "vs:%s:%s" % (socket.gethostname(), os.path.basename(self._get_vm_directory()))

	def _check_for_interrupted_build(self):
		if os.access(self._get_build_info_file(), os.F_OK):
			with open(self._get_build_info_file()) as build_file:
				build_id = yaml.load(build_file.read())['build_id']
				self._handle_interrupted_build(build_id)

	def _handle_interrupted_build(self, build_id):
		self.logger.warn("Worker %s found interrupted build with id %s. Failing build." % (self.worker_id, build_id))
		status = BuildStatus.FAILED
		with ModelServer.rpc_connect("builds", "update") as builds_update_rpc:
			builds_update_rpc.mark_build_finished(build_id, status)
		with Connection(RabbitSettings.kombu_connection_info).Producer(serializer='msgpack') as producer:
			producer.publish({'build_id': build_id, 'status': status},
				exchange=VerificationServerSettings.verification_results_queue.exchange,
				routing_key=VerificationServerSettings.verification_results_queue.routing_key,
				mandatory=True,
			)
		if os.access(self._get_build_info_file(), os.F_OK):
			os.remove(self._get_build_info_file())
		self.logger.debug("Failed interrupted build %s, resuming initialization" % build_id)

	def do_setup(self, message):
		self.build_id = message["build_id"]
		verification_config = VerificationConfig.from_dict(message["verification_config"])
		commit_list = self._get_commit_list(self.build_id)
		self.logger.info("Worker %s processing verification request: (build id: %s, commit list: %s)" % (self.worker_id, self.build_id, commit_list))
		self._start_build(self.build_id)
		repo_uri = self._get_repo_uri(commit_list[0])
		refs = self._get_ref_list(commit_list)
		private_key = self._get_private_key(repo_uri)
		with ModelServer.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
			console_appender = self._make_console_appender(build_consoles_update_rpc, self.build_id)
			self.verifier.setup_build(repo_uri, refs, private_key, console_appender)
			self.verifier.run_compile_step(verification_config.compile_commands, console_appender)

	def do_cleanup(self, results):
		with ModelServer.rpc_connect("builds", "update") as builds_update_rpc:
			callback = self._make_verify_callback(self.build_id, builds_update_rpc)
			# check that no results are exceptions
			success = not any(map(lambda result: isinstance(result, Exception), results))
			if success:
				self.verifier.mark_success(callback)
			else:
				self.verifier.mark_failure(callback)

	def do_task(self, task):
		try:
			test_command = SimpleRemoteTestCommand(task["test_command"])
			with ModelServer.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
				console_appender = self._make_console_appender(build_consoles_update_rpc, self.build_id)
				return self.verifier.run_test_command(test_command, console_appender)
		except Exception as e:
			self.logger.debug("Worker %s failed task %s" % (self.worker_id, task["test_command"]), exc_info=True)
			return e

	def _get_commit_list(self, build_id):
		with ModelServer.rpc_connect("builds", "read") as model_server_rpc:
			return model_server_rpc.get_commit_list(build_id)

	def _get_ref_list(self, commit_list):
		return [pathgen.hidden_ref(commit) for commit in commit_list]

	def _start_build(self, build_id):
		self.logger.debug("Worker %s starting build %s" % (self.worker_id, build_id))
		with ModelServer.rpc_connect("builds", "update") as model_server_rpc:
			model_server_rpc.start_build(build_id)
		with open(self._get_build_info_file(), 'w') as build_file:
			build_file.write(yaml.safe_dump({'build_id': build_id}))

	def _make_verify_callback(self, build_id, builds_update_rpc):
		"""Returns the default callback function to be
		called with a return value after verification.
		Sends a message denoting the return value and acks"""
		def default_verify_callback(status, cleanup_function=lambda: None):
			builds_update_rpc.mark_build_finished(build_id, status)
			with Connection(RabbitSettings.kombu_connection_info).Producer(serializer='msgpack') as producer:
				producer.publish({'build_id': build_id, 'status': status},
					exchange=VerificationServerSettings.verification_results_queue.exchange,
					routing_key=VerificationServerSettings.verification_results_queue.routing_key,
					mandatory=True,
				)
			self.logger.debug("Worker %s cleaning up before next run" % self.worker_id)
			if os.access(self._get_build_info_file(), os.F_OK):
				os.remove(self._get_build_info_file())
			cleanup_function()
		return default_verify_callback

	def _get_repo_uri(self, commit_id):
		"""Sends out a rpc call to the model server to retrieve
		the uri of a repository for a commit"""
		with ModelServer.rpc_connect("repos", "read") as model_server_rpc:
			return model_server_rpc.get_repo_uri(commit_id)

	def _get_private_key(self, repo_uri):
		with ModelServer.rpc_connect("repos", "read") as repos_read_rpc:
			repostore_id, ip_address, repo_path, repo_id, repo_name, private_key = repos_read_rpc.get_repo_attributes(repo_uri)
		return private_key

	def _make_console_appender(self, build_consoles_update_rpc, build_id):
		class ConsoleAppender(object):
			def __init__(self, type, subtype):
				self.build_consoles_update_rpc = build_consoles_update_rpc
				self.build_id = build_id
				self.type = type
				self.subtype = subtype

			def declare_command(self):
				self.build_consoles_update_rpc.add_subtypes(self.build_id, self.type, (self.subtype,))

			def append(self, read_lines):
				self.build_consoles_update_rpc.append_console_lines(self.build_id, read_lines, self.type, self.subtype)

			def set_return_code(self, return_code):
				self.build_consoles_update_rpc.set_return_code(self.build_id, return_code, self.type, self.subtype)

		return ConsoleAppender
