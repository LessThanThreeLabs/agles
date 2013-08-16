import os
import yaml

import model_server

from build_core import VerificationException
from pubkey_registrar import PubkeyRegistrar
from settings.store import StoreSettings
from shared.constants import BuildStatus, VerificationUser, KOALITY_EXPORT_PATH
from util import pathgen
from util.log import Logged
from verification_results_handler import VerificationResultsHandler


@Logged()
class BuildVerifier(object):
	def ReturnException(func):

		def wrapper(*args, **kwargs):
			try:
				return func(*args, **kwargs)
			except VerificationException as e:
				return e
			except BaseException as e:
				BuildVerifier.logger.critical("Unexpected exception thrown during verification", exc_info=True)
				return e

		return wrapper

	def __init__(self, build_core):
		self.build_core = build_core
		# TODO: change this to something else
		self.worker_id = build_core.virtual_machine.vm_id
		self._check_for_interrupted_build()
		self._register_pubkey()

	def _register_pubkey(self):
		PubkeyRegistrar().register_pubkey(VerificationUser.id, "BuildVerifier:%s" % self.worker_id)

	def _check_for_interrupted_build(self):
		build_id = self.build_core.virtual_machine.get_vm_metadata().get('build_id')
		if build_id is not None:
			self._handle_interrupted_build(build_id)

	def _handle_interrupted_build(self, build_id):
		self.logger.error("Worker %s found interrupted build with id %s. Failing build." % (self.worker_id, build_id))
		status = BuildStatus.FAILED
		with model_server.rpc_connect("builds", "update") as builds_update_rpc:
			builds_update_rpc.mark_build_finished(build_id, status)
		with model_server.rpc_connect("builds", "read") as builds_read_rpc:
			change_id = builds_read_rpc.get_build_from_id(build_id)['change_id']
		VerificationResultsHandler().fail_change(change_id)
		self.build_core.virtual_machine.remove_vm_metadata('build_id')
		self.logger.debug("Failed interrupted build %s, resuming initialization" % build_id)

	def setup(self):
		self.build_core.setup()

	def teardown(self):
		self.build_core.teardown()

	def rebuild(self):
		self.build_core.rebuild()

	def verify_build(self, build_id, patch_id, repo_type, verification_config, test_queue, artifact_export_event):
		results = []
		setup_result = self._setup(build_id, patch_id, repo_type, verification_config)
		results.append(setup_result)
		test_queue.add_other_result(setup_result)
		if isinstance(setup_result, Exception):
			if test_queue.can_populate_tasks():
				test_queue.begin_populating_tasks()
				test_queue.finish_populating_tasks()
			self._cleanup(build_id, results, artifact_export_event)
			return

		if test_queue.can_populate_tasks():
			population_result = self._populate_tests(build_id, verification_config, test_queue)
			results.append(population_result)
			test_queue.add_other_result(population_result)
		else:
			test_queue.wait_for_tasks_populated()

		for test_number, test in test_queue.task_iterator():
			test_result = self._do_test(build_id, test_number, test)
			results.append(test_result)
			test_queue.add_task_result(test_result)

		self._cleanup(build_id, results, artifact_export_event)

	@ReturnException
	def _setup(self, build_id, patch_id, repo_type, verification_config):
		build = self._get_build(build_id)
		commit_id = build['commit_id']
		self.logger.info("Worker %s processing verification request: (build id: %s, commit id: %s)" % (self.worker_id, build_id, commit_id))
		self._start_build(build_id)
		repo_uri = self._get_repo_uri(commit_id)

		if repo_type == "git":
			ref = pathgen.hidden_ref(commit_id)
		elif repo_type == "hg":
			ref = self._get_commit(commit_id)['sha']
		else:
			raise NoSuchRepoTypeError("Unknown repository type %s." % repo_type)

		private_key = StoreSettings.ssh_private_key
		with model_server.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
			console_appender = self._make_console_appender(build_consoles_update_rpc, build_id)
			self.build_core.setup_build(repo_uri, repo_type, ref, private_key, patch_id, console_appender)
			self.build_core.run_compile_step(verification_config.compile_commands, console_appender)

	@ReturnException
	def _populate_tests(self, build_id, verification_config, test_queue):
		test_queue.begin_populating_tasks()
		try:
			for factory_command in verification_config.test_factory_commands:
				with model_server.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
					console_appender = self._make_console_appender(build_consoles_update_rpc, build_id)
					generated_test_commands = self.build_core.run_factory_command(factory_command, console_appender)
				test_queue.populate_tasks(*generated_test_commands)
			test_queue.populate_tasks(*[test_command for test_command in verification_config.test_commands])
		finally:
			test_queue.finish_populating_tasks()

	@ReturnException
	def _do_test(self, build_id, test_number, test_command):
		with model_server.rpc_connect("build_consoles", "update") as build_consoles_update_rpc:
			console_appender = self._make_console_appender(build_consoles_update_rpc, build_id, test_number)
			return self.build_core.run_test_command(test_command, console_appender)

	@ReturnException
	def _cleanup(self, build_id, results, artifact_export_event):
		# check that no results are exceptions
		success = not any(map(lambda result: isinstance(result, Exception), results))
		build_status = BuildStatus.PASSED if success else BuildStatus.FAILED
		with model_server.rpc_connect("builds", "update") as builds_update_rpc:
			builds_update_rpc.mark_build_finished(build_id, build_status)
		self.logger.debug("Worker %s cleaning up before next run" % self.worker_id)

		build = self._get_build(build_id)
		export_prefix = "repo_%d/change_%d" % (build['repo_id'], build['change_id'])

		def parse_export_uris(export_results):
			if export_results.returncode == 0:
				try:
					return yaml.safe_load(export_results.output)['uris']
				except:
					pass
			return []

		try:
			export_uris = parse_export_uris(self.build_core.export_path(export_prefix, os.path.join(KOALITY_EXPORT_PATH, "test")))
		except:
			export_uris = []

		if not artifact_export_event.ready():
			artifact_export_event.send()
			try:
				results = self.build_core.export_path(export_prefix, os.path.join(KOALITY_EXPORT_PATH, "compile"))
				export_uris += parse_export_uris(results)
			except:
				pass

		with model_server.rpc_connect("changes", "update") as changes_update_rpc:
			changes_update_rpc.add_export_uris(build['change_id'], export_uris)

		commit_id = build['commit_id']
		repo_uri = self._get_repo_uri(commit_id)
		self.build_core.cache_repository(repo_uri)
		self.build_core.virtual_machine.remove_vm_metadata('build_id')

	def _get_build(self, build_id):
		with model_server.rpc_connect("builds", "read") as model_server_rpc:
			return model_server_rpc.get_build_from_id(build_id)

	def _get_commit(self, commit_id):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			return model_server_rpc.get_commit_attributes(commit_id)

	def _start_build(self, build_id):
		self.logger.debug("Worker %s starting build %s" % (self.worker_id, build_id))
		with model_server.rpc_connect("builds", "update") as model_server_rpc:
			model_server_rpc.start_build(build_id)
		self.build_core.virtual_machine.store_vm_metadata(build_id=build_id)

	def _get_repo_uri(self, commit_id):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			return model_server_rpc.get_repo_uri(commit_id)

	def _make_console_appender(self, build_consoles_update_rpc, build_id, priority=None):
		class ConsoleAppender(object):
			def __init__(self, type, subtype):
				self.build_consoles_update_rpc = build_consoles_update_rpc
				self.build_id = build_id
				self.type = type
				self.subtype = subtype

			def declare_command(self):
				self.build_consoles_update_rpc.add_subtype(self.build_id, self.type, self.subtype, priority)

			def append(self, read_lines):
				self.build_consoles_update_rpc.append_console_lines(self.build_id, read_lines, self.type, self.subtype)

			def set_return_code(self, return_code):
				self.build_consoles_update_rpc.set_return_code(self.build_id, return_code, self.type, self.subtype)

		return ConsoleAppender


class NoSuchRepoTypeError(Exception):
	pass
