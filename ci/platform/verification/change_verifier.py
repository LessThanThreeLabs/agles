import sys

from eventlet import event, spawn, spawn_n, queue
from kombu.messaging import Producer

import model_server

from build_core import LightWeightBuildCore
from shared.handler import EventSubscriber
from util import greenlets, pathgen
from util.log import Logged
from verification_results_handler import VerificationResultsHandler


@Logged()
class ChangeVerifier(EventSubscriber):
	def __init__(self, verifier_pool, uri_translator):
		super(ChangeVerifier, self).__init__('repos', 'verification:repos.update')
		self.verifier_pool = verifier_pool
		self.uri_translator = uri_translator
		self.results_handler = VerificationResultsHandler()

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(ChangeVerifier, self).bind(channel)

	def handle_message(self, body, message):
		if body['type'] == 'change added':
			self._handle_new_change(body['contents'])
		message.ack()

	def _handle_new_change(self, contents):
		change_id = contents["change_id"]
		commit_id = self._get_commit_id(change_id)
		verification_config = self._get_verification_config(commit_id)

		workers_spawned = event.Event()
		spawn_n(self.verify_change, verification_config, change_id, workers_spawned)
		workers_spawned.wait()

	def verify_change(self, verification_config, change_id, workers_spawned):
		task_queue = TaskQueue()
		num_workers = max(1, min(64, len(verification_config.test_commands)))

		self.logger.info("Verifying change %d with %d workers" % (change_id, num_workers))
		self.logger.debug("Verification config: %s" % verification_config.to_dict())

		task_queue.begin_populating_tasks()
		task_queue.populate_tasks(*(test_command for test_command in verification_config.test_commands))
		task_queue.finish_populating_tasks()

		workers_alive = []
		change_started = event.Event()
		change_done = event.Event()

		def cleanup_greenlet(greenlet, verifier):
			workers_alive.pop()
			if not workers_alive:
				task_queue.clear_remaining_tasks()
			self.verifier_pool.remove(verifier)
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
				return
			if not change_started.ready():
				start_change()
			if change_done.ready():  # We got a verifier after the change is already done
				self.verifier_pool.put(verifier)  # Just return this verifier to the pool
				return
			workers_alive.append(1)
			build_id = self._create_build(change_id)
			worker_greenlet = spawn(verifier.verify_build(build_id, verification_config, task_queue))
			worker_greenlet.link(cleanup_greenlet, verifier)

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

	def _get_commit_id(self, change_id):
		with model_server.rpc_connect("changes", "read") as model_server_rpc:
			return model_server_rpc.get_change_attributes(change_id)['commit_id']

	def _create_build(self, change_id):
		with model_server.rpc_connect("builds", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id)

	def _get_verification_config(self, commit_id):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repo_uri = model_server_rpc.get_repo_uri(commit_id)
		ref = pathgen.hidden_ref(commit_id)
		build_core = LightWeightBuildCore(self.uri_translator)
		verification_config = build_core.setup_build(repo_uri, ref)
		return verification_config

	def _is_result_failed(self, result):
		return isinstance(result, Exception)


class TaskQueue(object):
	def __init__(self):
		self.task_queue = queue.Queue()
		self.results_queue = queue.Queue()
		self.tasks_populating = event.Event()
		self.num_results_received = 0

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
			return self.task_queue.get(block=False)
		except queue.Empty:
			return None

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
