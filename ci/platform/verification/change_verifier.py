import logging

from eventlet import event, spawn, spawn_n, queue
from kombu.messaging import Producer

from build_core import SelfCleaningBuildCore
from model_server import ModelServer
from shared.handler import EventSubscriber
from util import greenlets, pathgen
from verification_results_handler import VerificationResultsHandler


class ChangeVerifier(EventSubscriber):
	logger = logging.getLogger("ChangeVerifier")

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
		commit_list = self._get_commit_permutations(change_id)[0]
		verification_config = self._get_verification_config(commit_list)

		change_started = event.Event()
		spawn_n(self.verify_change, verification_config, change_id, commit_list, change_started)
		change_started.wait()

	def verify_change(self, verification_config, change_id, commit_list, change_started):
		task_queue = TaskQueue()
		num_workers = max(1, min(64, len(verification_config.test_commands)))

		task_queue.begin_populating_tasks()
		task_queue.populate_tasks(*(test_command for test_command in verification_config.test_commands))
		task_queue.finish_populating_tasks()

		workers_alive = []
		change_done = event.Event()

		def cleanup_greenlet(greenlet, verifier):
			workers_alive.pop()
			if not workers_alive:
				task_queue.clear_remaining_tasks()
			self.verifier_pool.remove(verifier)
			raise greenlet.throw()

		def start_change():
			change_started.send(True)
			with ModelServer.rpc_connect("changes", "update") as model_server_rpc:
				model_server_rpc.mark_change_started(change_id)

		def setup_worker():
			verifier = self.verifier_pool.get()
			if change_done.ready():  # We got a verifier after the change is already done
				self.verifier_pool.put(verifier)  # Just return this verifier to the pool
				return
			if not change_started.ready():
				start_change()
			workers_alive.append(1)
			build_id = self._create_build(change_id, commit_list)
			worker_greenlet = spawn(verifier.verify_build(build_id, verification_config, task_queue))
			worker_greenlet.link(cleanup_greenlet, verifier)

		for worker in range(num_workers):
			spawn_n(setup_worker)

		task_queue.wait_for_tasks_populated()

		change_failed = False
		while task_queue.has_more_results():
			result = task_queue.get_result()
			if self._is_result_failed(result) and not change_failed:
				change_done.send(True)
				self.results_handler.fail_change(change_id)
				change_failed = True
		if not change_failed:
			change_done.send(True)
			self.results_handler.pass_change(change_id)

	def _get_commit_permutations(self, change_id):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit id
		return [[self._get_commit_id(change_id)]]

	def _get_commit_id(self, change_id):
		with ModelServer.rpc_connect("changes", "read") as model_server_rpc:
			return model_server_rpc.get_change_attributes(change_id)['commit_id']

	def _create_build(self, change_id, commit_list):
		with ModelServer.rpc_connect("builds", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id, commit_list)

	def _get_verification_config(self, commit_list):
		with ModelServer.rpc_connect("repos", "read") as model_server_rpc:
			repo_uri = model_server_rpc.get_repo_uri(commit_list[0])
		refs = [pathgen.hidden_ref(commit) for commit in commit_list]
		build_core = SelfCleaningBuildCore(self.uri_translator)
		verification_config = build_core.setup_build(repo_uri, refs)
		return verification_config

	def _is_result_failed(self, result):
		return isinstance(result, Exception)


class TaskQueue(object):
	def __init__(self):
		self.task_queue = queue.Queue()
		self.results_queue = queue.Queue()
		self.tasks_populating = event.Event()

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

	def add_result(self, result):
		self.results_queue.put(result)
		if self.task_queue.unfinished_tasks:
			self.task_queue.task_done()

	def get_result(self):
		return self.results_queue.get()

	def has_more_results(self):
		return self.task_queue.unfinished_tasks > 0 or not self.results_queue.empty()

	def clear_remaining_tasks(self):
		for task in self.task_iterator():
			self.add_result(None)
		for x in range(self.task_queue.unfinished_tasks):
			self.add_result(None)
