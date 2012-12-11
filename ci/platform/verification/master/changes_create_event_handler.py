import random
import time

from kombu.messaging import Producer

from shared.handler import EventSubscriber
from model_server import ModelServer
from settings.verification_server import *
from task_queue.task_queue import TaskQueue
from util import pathgen
from verification.shared.build_core import BuildCore
from verification.shared.pubkey_registrar import PubkeyRegistrar


class ChangesCreateEventHandler(EventSubscriber):
	def __init__(self, uri_translator):
		super(ChangesCreateEventHandler, self).__init__("repos", "verification_master:repos.update")
		self.uri_translator = uri_translator
		self._register_pubkey()

	def _register_pubkey(self):
		PubkeyRegistrar().register_pubkey(VerificationUser.id, str(random.random())[2:])

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		super(ChangesCreateEventHandler, self).bind(channel)

	def handle_message(self, body, message):
		try:
			if body["type"] == "change added":
				self._handle_new_change(body["contents"])
			message.channel.basic_ack(delivery_tag=message.delivery_tag)
		except Exception as e:
			message.channel.basic_reject(delivery_tag=message.delivery_tag, requeue=True)
			raise e  # Should log this

	def _handle_new_change(self, contents):
		change_id = contents["change_id"]
		commit_list = self._get_commit_permutations(change_id)[0]
		test_commands = self._get_test_commands(commit_list)
		num_workers = max(1, min(4, len(test_commands)))  # between 1 and 4 workers
		task_queue = TaskQueue()
		workers = task_queue.get_workers(num_workers, verification_request_queue)
		if not workers:
			raise NoWorkersFoundException()
		with ModelServer.rpc_connect("changes", "update") as model_server_rpc:
			model_server_rpc.mark_change_started(change_id)
		self._send_verification_request(change_id, task_queue, workers, commit_list, test_commands)

	def _get_commit_id(self, change_id):
		with ModelServer.rpc_connect("changes", "read") as model_server_rpc:
			return model_server_rpc.get_change_attributes(change_id)[0]

	def _create_build(self, change_id, commit_list, is_primary):
		with ModelServer.rpc_connect("builds", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id, commit_list, is_primary)

	def _get_commit_permutations(self, change_id):
		# TODO (bbland): do something more useful than this trivial case
		# This is a single permutation which is a single commit id
		return [[self._get_commit_id(change_id)]]

	def _send_verification_request(self, change_id, task_queue, workers, commit_list, test_commands):
		for test_command in test_commands:
			task_queue.delegate_task({"test_command": test_command.name})
		is_primary = True
		for worker in workers.itervalues():
			build_id = self._create_build(change_id, commit_list, is_primary)
			task_queue.assign_worker(worker, {"build_id": build_id})
			print "Sending verification request for " + str(build_id)
			is_primary = False

	def _get_test_commands(self, commit_list):
		with ModelServer.rpc_connect("repos", "read") as model_server_rpc:
			repo_uri = model_server_rpc.get_repo_uri(commit_list[0])
		refs = [pathgen.hidden_ref(commit) for commit in commit_list]
		build_core = BuildCore(self.uri_translator)
		verification_config = build_core.setup_build(repo_uri, refs)
		return verification_config.test_commands


class NoWorkersFoundException(Exception):
	def __init__(self, wait_time=2):
		super(NoWorkersFoundException, self).__init__()
		time.sleep(wait_time)  # chill out before hammering the server
