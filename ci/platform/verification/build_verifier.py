import logging
import os
import socket
import yaml

from model_server import ModelServer
from pubkey_registrar import PubkeyRegistrar
from shared.constants import BuildStatus, VerificationUser
from util import pathgen


def ReturnException(func):

	def wrapper(*args, **kwargs):
		try:
			return func(*args, **kwargs)
		except Exception as e:
			return e

	return wrapper


class BuildVerifier(object):
	def __init__(self, build_core):
		self.logger = logging.getLogger("BuildVerifier")
		self.build_core = build_core
		# self._check_for_interrupted_build()
		# TODO: change this to something else
		self.worker_id = os.path.basename(os.path.abspath(build_core.virtual_machine.vm_directory))
		self._register_pubkey()

	def _register_pubkey(self):
		PubkeyRegistrar().register_pubkey(VerificationUser.id, self.worker_id)

	def _get_vm_directory(self):
		return os.path.abspath(self.build_core.virtual_machine.vm_directory)

	def _get_build_info_file(self):
		return os.path.abspath(os.path.join(self._get_vm_directory(), '.build'))

	def get_worker_id(self):
		return "vs:%s:%s" % (socket.gethostname(), os.path.basename(self._get_vm_directory()))

	# def _check_for_interrupted_build(self):
	# 	if os.access(self._get_build_info_file(), os.F_OK):
	# 		with open(self._get_build_info_file()) as build_file:
	# 			build_id = yaml.load(build_file.read())['build_id']
	# 			self._handle_interrupted_build(build_id)

	# def _handle_interrupted_build(self, build_id):
	# 	self.logger.warn("Worker %s found interrupted build with id %s. Failing build." % (self.worker_id, build_id))
	# 	status = BuildStatus.FAILED
	# 	with ModelServer.rpc_connect("builds", "update") as builds_update_rpc:
	# 		builds_update_rpc.mark_build_finished(build_id, status)
	# 	with Connection(RabbitSettings.kombu_connection_info).Producer(serializer='msgpack') as producer:
	# 		producer.publish({'build_id': build_id, 'status': status},
	# 			exchange=VerificationServerSettings.verification_results_queue.exchange,
	# 			routing_key=VerificationServerSettings.verification_results_queue.routing_key,
	# 			mandatory=True,
	# 		)
	# 	if os.access(self._get_build_info_file(), os.F_OK):
	# 		os.remove(self._get_build_info_file())
	# 	self.logger.debug("Failed interrupted build %s, resuming initialization" % build_id)

	def verify_build(self, build_id, verification_config, test_queue):
		results = []
		setup_result = self._setup(build_id, verification_config)
		results.append(setup_result)
		test_queue.add_other_result(setup_result)
		if isinstance(setup_result, Exception):
			self._cleanup(build_id, results)
			return

		if test_queue.can_populate_tasks():
			self._populate_tests(test_queue)
		else:
			test_queue.wait_for_tasks_populated()

		for test in test_queue.task_iterator():
			test_result = self._do_test(build_id, test)
			results.append(test_result)
			test_queue.add_task_result(test_result)

		self._cleanup(build_id, results)

	@ReturnException
	def _setup(self, build_id, verification_config):
		commit_list = self._get_commit_list(build_id)
		self.logger.info("Worker %s processing verification request: (build id: %s, commit list: %s)" % (self.worker_id, build_id, commit_list))
		self._start_build(build_id)
		repo_uri = self._get_repo_uri(commit_list[0])
		refs = self._get_ref_list(commit_list)
		private_key = self._get_private_key(repo_uri)
		with ModelServer.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
			console_appender = self._make_console_appender(build_consoles_update_rpc, build_id)
			self.build_core.setup_build(repo_uri, refs, private_key, console_appender)
			self.build_core.run_compile_step(verification_config.compile_commands, console_appender)

	@ReturnException
	def _populate_tests(self, test_queue):
		raise NotImplementedError("Should never reach here yet")

	@ReturnException
	def _do_test(self, build_id, test_command):
		with ModelServer.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
			console_appender = self._make_console_appender(build_consoles_update_rpc, build_id)
			return self.build_core.run_test_command(test_command, console_appender)

	@ReturnException
	def _cleanup(self, build_id, results):
		# check that no results are exceptions
		success = not any(map(lambda result: isinstance(result, Exception), results))
		build_status = BuildStatus.PASSED if success else BuildStatus.FAILED
		with ModelServer.rpc_connect("builds", "update") as builds_update_rpc:
			builds_update_rpc.mark_build_finished(build_id, build_status)
		self.logger.debug("Worker %s cleaning up before next run" % self.worker_id)
		if os.access(self._get_build_info_file(), os.F_OK):
			os.remove(self._get_build_info_file())
		self.build_core.teardown()

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
				self.build_consoles_update_rpc.add_subtype(self.build_id, self.type, self.subtype)

			def append(self, read_lines):
				self.build_consoles_update_rpc.append_console_lines(self.build_id, read_lines, self.type, self.subtype)

			def set_return_code(self, return_code):
				self.build_consoles_update_rpc.set_return_code(self.build_id, return_code, self.type, self.subtype)

		return ConsoleAppender
