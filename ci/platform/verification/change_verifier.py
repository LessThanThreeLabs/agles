import collections
import os
import sys

from eventlet import event, spawn, spawn_n, spawn_after, queue
from kombu.messaging import Producer

import model_server

from build_core import VerificationException
from pubkey_registrar import PubkeyRegistrar
from shared.constants import VerificationUser
from shared.handler import EventSubscriber, ResourceBinding
from settings.deployment import DeploymentSettings
from settings.store import StoreSettings
from settings.verification_server import VerificationServerSettings
from streaming_executor import StreamingExecutor
from util import pathgen
from util.log import Logged
from verification.verifier_pool import VirtualMachineVerifierPool
from verification_config import VerificationConfig, ParseErrorVerificationConfig
from verification_results_handler import VerificationResultsHandler

@Logged()
class ChangeVerifier(EventSubscriber):
	def __init__(self, verifier_pools, uri_translator):
		super(ChangeVerifier, self).__init__([
			ResourceBinding('repos', 'verification:repos.update'),
			ResourceBinding('changes', 'instance_launching'),
			ResourceBinding('system_settings', None)
		])
		assert isinstance(verifier_pools, dict)
		assert 0 in verifier_pools
		self.verifier_pools = verifier_pools
		self.uri_translator = uri_translator
		self.results_handler = VerificationResultsHandler()

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(ChangeVerifier, self).bind(channel)

	def handle_message(self, body, message):
		if body['type'] == 'change added':
			self._handle_new_change(body['contents'])
		elif body['type'] == 'verifier pool settings updated':
			self._handle_verifier_settings_update(body['contents'])
		elif body['type'] == 'verifier pool created':
			self._handle_verifier_pool_created(body['contents'])
		elif body['type'] == 'verifier pool deleted':
			self._handle_verifier_pool_deleted(body['contents'])
		elif body['type'] == 'launch debug machine':
			self._handle_launch_debug(body['contents'])
		message.ack()

	def _handle_new_change(self, contents):
		try:
			change_id = contents['change_id']
			commit_id = contents['commit']['id']
			head_sha = contents['commit']['sha']
			base_sha = contents['commit'].get('base_sha')
			repo_id = contents['commit']['repo_id']
			repo_type = contents['repo_type']
			merge_target = contents['merge_target']
			patch_id = contents['patch_id']
			verify_only = contents['verify_only']

			if contents['skip'] or (not DeploymentSettings.active):
				self.skip_change(change_id)
				return

			verification_config = self._get_verification_config(commit_id, head_sha, base_sha, change_id, merge_target, patch_id, repo_id, repo_type)

			workers_spawned = event.Event()
			spawn_n(self.verify_change, verification_config, change_id, repo_type, workers_spawned, verify_only, patch_id)
			workers_spawned.wait()
		except:
			self.logger.critical("Unexpected failure while verifying change %d, commit %d. Failing change." % (change_id, commit_id), exc_info=True)
			self.results_handler.fail_change(change_id)

	def _handle_verifier_settings_update(self, contents):
		try:
			max_running = contents["max_running"]
			min_ready = contents["min_ready"]
			pool_id = contents.get("pool_id", 0)

			if pool_id not in self.verifier_pools:
				self.logger.error("Tried to update nonexistent verifier pool with id: %s." % pool_id)
				return

			verifier_pool = self.verifier_pools[pool_id]
			verifier_pool.reinitialize(max_running=max_running, min_ready=min_ready)
		except:
			self.logger.critical("Unexpected failure while updating verifier pool to %s." % contents, exc_info=True)

	def _handle_verifier_pool_created(self, contents):
		try:
			max_running = contents["max_running"]
			min_ready = contents["min_ready"]
			pool_id = contents["pool_id"]

			if pool_id in self.verifier_pools:
				self.logger.error("Verifier pool with id %s already exists." % pool_id)
				return

			primary_pool = self.verifier_pools[0]
			verifier_pool = VirtualMachineVerifierPool(primary_pool.virtual_machine_class, max_running=max_running, min_ready=min_ready, uri_translator=primary_pool.uri_translator, pool_id=pool_id)
			self.verifier_pools[pool_id] = verifier_pool
		except:
			self.logger.critical("Unexpected failure while creating verifier pool %s." % contents, exc_info=True)

	def _handle_verifier_pool_deleted(self, contents):
		try:
			pool_id = contents["pool_id"]

			if pool_id not in self.verifier_pools:
				self.logger.error("Tried to delete nonexistent verifier pool with id: %s." % pool_id)
				return

			verifier_pool = self.verifier_pools.pop(pool_id)
			verifier_pool.reinitialize(max_running=0, min_ready=0)
		except:
			self.logger.critical("Unexpected failure while deleting verifier pool %s." % contents, exc_info=True)

	# TODO(andrey) This should eventually not be in change_verifier.
	def _handle_launch_debug(self, contents):
		def launch_debug_instance():
			try:
				change_id = contents['change_id']

				with model_server.rpc_connect("changes", "read") as client:
					change_attributes = client.get_change_attributes(change_id)

				commit_id = change_attributes['commit_id']
				merge_target = change_attributes['merge_target']
				repo_id = change_attributes['repo_id']

				with model_server.rpc_connect("repos", "read") as client:
					repo_type = client.get_repo_type(repo_id)
					commit_attributes = client.get_commit_attributes(commit_id)

				head_sha = commit_attributes['sha']
				base_sha = commit_attributes['base_sha']

				user_id = contents['user_id']

				verification_config = self._get_verification_config(commit_id, head_sha, base_sha, change_id, merge_target, None, repo_id, repo_type)

				if verification_config.pool_id not in self.verifier_pools:
					error_message = "Tried to launch debug instance for nonexistent verifier pool with id: %s." % verification_config.pool_id
					self.logger.error(error_message)
					raise Exception(error_message)

				verifier_pool = self.verifier_pools[verification_config.pool_id]

				verifier = None
				try:
					verifier = verifier_pool.get()
					verifier.setup()
				except:
					if verifier is not None:
						verifier_pool.remove(verifier)
					return

				def scrap_instance():
					verifier.teardown()
					verifier_pool.remove(verifier)

				debug_instance = spawn(verifier.launch_build, commit_id, repo_type, verification_config)

				try:
					debug_instance.wait() # Make sure that the instance has launched before we start the cleanup timer and inform the user.
				except VerificationException:
					pass  # TODO (akostov): tell the user that provisioning failed

				spawn_after(contents['timeout'], scrap_instance)
				with model_server.rpc_connect("debug_instances", "update") as debug_update_rpc:
					debug_update_rpc.mark_debug_instance_launched(verifier.build_core.virtual_machine.instance.id, user_id, contents['timeout'])
			except:
				exc_info = sys.exc_info()
				scrap_instance()
				self.logger.critical("Unexpected failure while trying to launch a debug instance for change %s and user %s." % (change_id, user_id), exc_info=exc_info)
				raise exc_info[0], exc_info[1], exc_info[2]

		spawn(launch_debug_instance)

	def skip_change(self, change_id):
		self.results_handler.skip_change(change_id)

	def verify_change(self, verification_config, change_id, repo_type, workers_spawned, verify_only, patch_id=None):
		task_queue = TaskQueue()

		if verification_config.pool_id not in self.verifier_pools:
			error_message = "Tried to launch change for nonexistent verifier pool with id: %s." % verification_config.pool_id
			self.logger.error(error_message)
			raise Exception(error_message)

		verifier_pool = self.verifier_pools[verification_config.pool_id]

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
				verifier_pool.remove(verifier)
			else:
				verifier_pool.put(verifier)
			raise greenlet.throw()

		def start_change():
			change_started.send(True)
			with model_server.rpc_connect("changes", "update") as model_server_rpc:
				model_server_rpc.mark_change_started(change_id)

		def pass_change(verify_only):
			change_done.send(True)
			self.results_handler.pass_change(change_id, verify_only)

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
			verifier = None
			try:
				verifier = verifier_pool.get()
				verifier.setup()
			except:
				prematurely_fail_change(sys.exc_info())
				if verifier is not None:
					verifier_pool.remove(verifier)
				return
			if not change_started.ready():
				start_change()
			if change_done.ready():  # We got a verifier after the change is already done
				verifier_pool.put(verifier)  # Just return this verifier to the pool
				return
			workers_alive.append(1)
			change_index = len(workers_alive) - 1
			build_id = self._create_build(change_id)
			worker_greenlet = spawn(verifier.verify_build, build_id, patch_id, repo_type, verification_config, task_queue, change_index)

			def cleanup_greenlet(greenlet):
				workers_alive.pop()
				if not workers_alive:
					task_queue.clear_remaining_tasks()
				if VerificationServerSettings.teardown_after_build:
					verifier.teardown()
					verifier_pool.remove(verifier)
				else:
					verifier_pool.put(verifier)
				raise greenlet.throw()

			worker_greenlet.link(cleanup_greenlet)

		for worker in range(num_workers):
			spawn_n(setup_worker)

		workers_spawned.send(True)

		task_queue.wait_for_tasks_populated()

		if not change_started.wait():
			return  # Failed prematurely


		default_results_collected = False
		change_failed = False
		while task_queue.has_more_results():
			task_result = task_queue.get_result()
			if task_result.type == 'other':
				if not default_results_collected and task_result.is_failed() and not change_failed:
					# There's a race condition here. A greenthread can switch here a worker ends up moving to the else clause, then we call change failed. Paradise lost
					fail_change()
					change_failed = True
			else:
				default_results_collected = True
				if task_result.is_failed() and not change_failed:
					fail_change()
					change_failed = True

		if not change_failed:
			pass_change(verify_only)

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

	def _get_verification_config(self, commit_id, head_sha, base_sha, change_id, merge_target, patch_id, repo_id, repo_type):
		with model_server.rpc_connect("repos", "read") as model_server_rpc:
			repo_uri = model_server_rpc.get_repo_uri(commit_id)
			attributes = model_server_rpc.get_repo_attributes(repo_uri)

		repo_name = attributes['repo']['name']

		PubkeyRegistrar().register_pubkey(VerificationUser.id, "ChangeVerifier")
		PubkeyRegistrar().register_pubkey(VerificationUser.id, "Koality Keypair", StoreSettings.ssh_public_key)

		config_yaml = None

		if repo_type == 'git':
			ref = pathgen.hidden_ref(commit_id)

			if self.uri_translator:
				checkout_url = self.uri_translator.translate(repo_uri)
				host_url = checkout_url[:checkout_url.find(":")]
				repo_path = checkout_url[checkout_url.find(":") + 1:]

				local_ref = ref

				show_command = lambda file_name: ["ssh", "-q", "-oStrictHostKeyChecking=no", host_url, "git-show", repo_path, "%s:%s" % (local_ref, file_name)]
				checkout_url = attributes['repo']['forward_url']
				ref = "refs/pending/%s" % head_sha
			else:
				checkout_url = repo_uri
				show_command = lambda file_name: ["bash", "-c", "cd %s && git show %s:%s" % (repo_uri, ref, file_name)]
		elif repo_type == 'hg':
			ref = head_sha
			if self.uri_translator:
				checkout_url = self.uri_translator.translate(repo_uri)
				host_url, _, repo_uri = checkout_url.split('://')[1].partition('/')
				show_command = lambda file_name: ["ssh", "-q", "-oStrictHostKeyChecking=no", host_url, "hg", "show-koality", repo_uri, ref, file_name]
			else:
				# TODO(andrey) Test this case!
				checkout_url = repo_uri
				show_command = lambda file_name: ["bash", "-c", "cd %s && hg -R %s cat -r tip %s" % ((repo_uri, os.path.join(repo_uri, ".hg", "strip-backup", head_sha + ".hg")), file_name)]
		else:
			self.logger.critical('Unexpected repo type specified for verification: %s' % repo_type)
			assert False

		for file_name in ['koality.yml', '.koality.yml']:
			results = StreamingExecutor().execute(show_command(file_name))
			if results.returncode == 0:
				try:
					config_yaml = results.output
				except:
					pass
				else:
					break

		environment = collections.OrderedDict()
		environment['KOALITY'] = 'true'
		environment['KOALITY_HEAD_SHA'] = head_sha
		if base_sha:
			environment['KOALITY_BASE_SHA'] = base_sha
		environment['KOALITY_BRANCH'] = merge_target
		environment['KOALITY_REPOSITORY'] = repo_name
		environment['KOALITY_REPOSITORY_ID'] = str(repo_id)
		environment['KOALITY_CHANGE_ID'] = str(change_id)

		try:
			return VerificationConfig.from_yaml(repo_type, repo_name, checkout_url, ref, environment, config_yaml, private_key=StoreSettings.ssh_private_key, patch_id=patch_id)
		except:
			exc_info = sys.exc_info()
			self.logger.critical("Unexpected exception while getting verification configuration", exc_info=exc_info)
			return ParseErrorVerificationConfig(exc_info[1])


class TaskResult(object):
	def __init__(self, type, result):
		self.type = type
		self.result = result

	def is_failed(self):
		return isinstance(self.result, Exception)


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
		task_result = TaskResult('default', result)
		self.results_queue.put(task_result)
		self.task_queue.task_done()
		self.num_results_received = self.num_results_received + 1

	def add_other_result(self, result):
		task_result = TaskResult('other', result)
		self.results_queue.put(task_result)
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
