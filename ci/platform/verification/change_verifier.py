import subprocess
import sys

import yaml
import os

from eventlet import event, spawn, spawn_n, queue
from kombu.messaging import Producer

import model_server

from shared.handler import EventSubscriber, ResourceBinding
from settings.deployment import DeploymentSettings
from settings.verification_server import VerificationServerSettings
from util import greenlets, pathgen
from util.log import Logged
from verification_config import VerificationConfig
from verification_results_handler import VerificationResultsHandler


@Logged()
class ChangeVerifier(EventSubscriber):
	def __init__(self, verifier_pool, uri_translator):
		super(ChangeVerifier, self).__init__([
			ResourceBinding('repos', 'verification:repos.update'),
			ResourceBinding('system_settings', None)
		])
		self.verifier_pool = verifier_pool
		self.uri_translator = uri_translator
		self.results_handler = VerificationResultsHandler()

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(ChangeVerifier, self).bind(channel)

	def handle_message(self, body, message):
		if body['type'] == 'change added':
			self._handle_new_change(body['contents'])
		elif body['type'] == 'instance settings updated':
			self._handle_verifier_settings_update(body['contents'])
		message.ack()

	def _handle_new_change(self, contents):
		try:
			change_id = contents['change_id']
			commit_id = contents['commit']['id']
			sha = contents['commit']['sha']
			repo_type = contents['repo_type']
			patch_id = contents['patch_id']

			if not DeploymentSettings.active:
				self.skip_change(change_id)
				return

			verification_config = self._get_verification_config(commit_id, sha, repo_type)

			workers_spawned = event.Event()
			spawn_n(self.verify_change, verification_config, change_id, repo_type, workers_spawned, patch_id)
			workers_spawned.wait()
		except:
			self.logger.critical("Unexpected failure while verifying change %d, commit %d. Failing change." % (change_id, commit_id), exc_info=True)
			self.results_handler.fail_change(change_id)

	def _handle_verifier_settings_update(self, contents):
		try:
			max_verifiers = contents["max_verifiers"]
			min_ready = contents["min_ready"]
			self.verifier_pool.reinitialize(max_verifiers=max_verifiers, min_ready=min_ready)
		except:
			self.logger.critical("Unexpected failure while updating verifier pool to max_verifiers: %s, min_ready: %s." % (max_verifiers, min_ready), exc_info=True)

	def skip_change(self, change_id):
		self.results_handler.skip_change(change_id)

	def verify_change(self, verification_config, change_id, repo_type, workers_spawned, patch_id=None):
		task_queue = TaskQueue()
		artifact_export_event = event.Event()

		num_workers = self._get_num_workers(verification_config)

		self.logger.info("Verifying change %d with %d workers" % (change_id, num_workers))

		# This list is only used as a counter (we only care about its len)
		# We can't use an int because of function scoping and integer assignment
		# TODO(jchu): find a better way to do this
		workers_alive = []
		change_started = event.Event()
		change_done = event.Event()

		def cleanup_greenlet(greenlet, verifier):
			workers_alive.pop()
			if not workers_alive:
				task_queue.clear_remaining_tasks()
			if VerificationServerSettings.teardown_after_build:
				verifier.teardown()
				self.verifier_pool.remove(verifier)
			else:
				self.verifier_pool.put(verifier)
			raise greenlet.throw()

		def start_change():
			change_started.send(True)
			with model_server.rpc_connect("changes", "update") as model_server_rpc:
				model_server_rpc.mark_change_started(change_id)

		def pass_change():
			change_done.send(True)
			self.results_handler.pass_change(change_id)

		def fail_change():
			change_done.send(False)
			self.results_handler.fail_change(change_id)

		def prematurely_fail_change(exc_info):
			'''Marks that a verifier failed to initialize.
			If the first verifier hits this state, then all subsequent ones will go into the ready pool if they succeed,
			or do nothing if they fail.
			If a verifier reaches this state after another one sets up correctly,
			we just ignore this and run with one fewer verifier.
			'''
			if not change_started.ready():
				change_started.send(False)
				self.logger.error("Prematurely failed change %d" % change_id, exc_info=exc_info)
				fail_change()

		def setup_worker():
			try:
				verifier = self.verifier_pool.get()
				verifier.setup()
			except:
				prematurely_fail_change(sys.exc_info())
				if verifier is not None:
					self.verifier_pool.remove(verifier)
				return
			if not change_started.ready():
				start_change()
			if change_done.ready():  # We got a verifier after the change is already done
				self.verifier_pool.put(verifier)  # Just return this verifier to the pool
				return
			workers_alive.append(1)
			build_id = self._create_build(change_id)
			worker_greenlet = spawn(verifier.verify_build(build_id, patch_id, repo_type, verification_config, task_queue, artifact_export_event))

			def cleanup_greenlet(greenlet):
				workers_alive.pop()
				if not workers_alive:
					task_queue.clear_remaining_tasks()
				if VerificationServerSettings.teardown_after_build:
					verifier.teardown()
					self.verifier_pool.remove(verifier)
				else:
					self.verifier_pool.put(verifier)
				raise greenlet.throw()

			worker_greenlet.link(cleanup_greenlet)

		for worker in range(num_workers):
			spawn_n(setup_worker)

		workers_spawned.send(True)

		task_queue.wait_for_tasks_populated()

		if not change_started.wait():
			return  # Failed prematurely

		change_failed = False
		while task_queue.has_more_results():
			result = task_queue.get_result()
			if self._is_result_failed(result) and not change_failed:
				fail_change()
				change_failed = True
		if not change_failed:
			pass_change()

	def _get_num_workers(self, verification_config):
		if verification_config.test_factory_commands:
			if verification_config.machines:
				num_workers = max(1, verification_config.machines)
			else:
				num_workers = max(1, len(verification_config.test_commands))
		else:
			if verification_config.machines:
				num_workers = max(1, min(verification_config.machines, len(verification_config.test_commands)))
			else:
				num_workers = max(1, len(verification_config.test_commands))
		# TODO: give a warning if the parallelization was capped
		return min(VerificationServerSettings.parallelization_cap, num_workers)

	def _create_build(self, change_id):
		with model_server.rpc_connect("builds", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id)

	def _get_verification_config(self, commit_id, sha, repo_type):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repo_uri = model_server_rpc.get_repo_uri(commit_id)

		config_dict = {}

		if repo_type == 'git':
			ref = pathgen.hidden_ref(commit_id)

			if self.uri_translator:
				checkout_url = self.uri_translator.translate(repo_uri)
				host_url = checkout_url[:checkout_url.find(":")]
				repo_path = checkout_url[checkout_url.find(":") + 1:]
				show_command = lambda file_name: ["ssh", "-q", "-oStrictHostKeyChecking=no", host_url, "git-show", repo_path, "%s:%s" % (ref, file_name)]
			else:
				show_command = lambda file_name: ["bash", "-c", "cd %s && git show %s:%s" % (repo_uri, ref, file_name)]

			for file_name in ['koality.yml', '.koality.yml']:
				try:
					config_dict = yaml.safe_load(subprocess.check_output(show_command(file_name)))
				except:
					pass
				else:
					break
		elif repo_type == 'hg':
			if self.uri_translator:
				checkout_url = self.uri_translator.translate(repo_uri)
				host_url, _, repo_uri = checkout_url.split('://')[1].partition('/')
				show_command = ["ssh", "-q", "-oStrictHostKeyChecking=no", host_url, "hg", "show-koality", repo_uri, sha]
			else:
				# TODO(andrey) Test this case!
				show_command = ["bash", "-c", "cat %s" % os.path.join(repo_uri, ".hg", "strip-backup", sha + "-koality.yml")]
			try:
				config_dict = yaml.safe_load(subprocess.check_output(show_command))
			except:
				pass

		else:
			self.logger.critical()
			assert False

		if not isinstance(config_dict, dict):
			config_dict = {}

		try:
			return VerificationConfig(config_dict.get("compile", {}), config_dict.get("test", {}))
		except:
			self.logger.critical("Unexpected exception while getting verification configuration", exc_info=True)
			return VerificationConfig({}, {})

	def _is_result_failed(self, result):
		return isinstance(result, Exception)


class TaskQueue(object):
	def __init__(self):
		self.task_queue = queue.Queue()
		self.results_queue = queue.Queue()
		self.tasks_populating = event.Event()
		self.num_results_received = 0
		self.task_number = 0

	def can_populate_tasks(self):
		return not self.tasks_populating.ready()

	def wait_for_tasks_populated(self):
		tasks_populated = self.tasks_populating.wait()
		tasks_populated.wait()

	def begin_populating_tasks(self):
		assert self.can_populate_tasks()
		self.tasks_populated = event.Event()
		self.tasks_populating.send(self.tasks_populated)

	def populate_tasks(self, *tasks):
		for task in tasks:
			self.task_queue.put(task)

	def finish_populating_tasks(self):
		self.tasks_populated.send()

	def get_task(self):
		try:
			task = self.task_queue.get(block=False)
		except queue.Empty:
			return None
		else:
			ret = (self.task_number, task)
			self.task_number += 1
			return ret

	def task_iterator(self):
		while True:
			task = self.get_task()
			if task:
				yield task
			else:
				break

	def add_task_result(self, result):
		self.results_queue.put(result)
		self.task_queue.task_done()
		self.num_results_received = self.num_results_received + 1

	def add_other_result(self, result):
		self.results_queue.put(result)
		self.num_results_received = self.num_results_received + 1

	def get_result(self):
		return self.results_queue.get()

	def has_more_results(self):
		return self.task_queue.unfinished_tasks > 0 or not self.results_queue.empty() or self.num_results_received == 0

	def clear_remaining_tasks(self):
		for task in self.task_iterator():
			self.add_task_result(None)
		for x in range(self.task_queue.unfinished_tasks):
			self.add_task_result(None)
