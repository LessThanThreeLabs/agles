""" mixins.py - contains test mixins

This module contains all mixins meant to be used for unit testing.

Mixins are NOT meant to be instantiated and should never be instantiated.
Instantiating a mixin violates the mixin paradigm and will have unintended side
consequences/side effects.
"""
import os
import subprocess

import eventlet

from kombu.connection import Connection

from database.engine import ConnectionFactory
from model_server import ModelServer
from settings.rabbit import RabbitSettings

FILEDIR = os.path.dirname(os.path.realpath(__file__))
REDISCONF = os.path.join(FILEDIR, '..', '..', 'conf', 'redis', 'filesystem_repo_server_redis.conf')


class BaseTestMixin(object):
	"""A base class for testing mixins."""
	pass


class GreenProcess(object):
	def __init__(self, group=None, target=None, name=None, args=(), kwargs={}):
		self.target = target
		self.args = args
		self.kwargs = kwargs

	def start(self):
		self.greenlet = eventlet.spawn(self.target, *self.args, **self.kwargs)

	def terminate(self):
		self.greenlet.kill()

	def join(self):
		try:
			self.greenlet.wait()
		except:
			pass

	@classmethod
	def _with_new_engine(cls, method):
		def wrapped_method(*args, **kwargs):
			ConnectionFactory.recreate_engine()
			method(*args, **kwargs)
		return wrapped_method


class ModelServerTestMixin(BaseTestMixin):
	"""Mixin for integration tests that require a running model server"""

	def _start_model_server(self):
		connection = Connection(RabbitSettings.kombu_connection_info)
		self.model_server_channel = connection.channel()
		self.model_server_process = GreenProcess(target=ModelServer(self.model_server_channel).start)
		self.model_server_process.start()

	def _stop_model_server(self):
		self.model_server_process.terminate()
		self.model_server_process.join()
		self.model_server_channel.close()


class RabbitMixin(BaseTestMixin):
	def _purge_queues(self):
		command = """rabbitmqadmin -u %s -p %s -f tsv -q list queues name messages|
			while read queue count;
			do if [ ${count} -gt "0" ];
				then rabbitmqadmin -u %s -p %s -q purge queue name=${queue};
			fi;
			done""" % (RabbitSettings.rabbit_username, RabbitSettings.rabbit_password,
				RabbitSettings.rabbit_username, RabbitSettings.rabbit_password)
		subprocess.call(command, shell=True)


class RepoStoreTestMixin(BaseTestMixin):
	def _modify_commit_push(self, repo, filename, contents, parent_commits=None, refspec="HEAD:master"):
		with open(os.path.join(repo.working_dir, filename), "w") as f:
			f.write(contents)
		repo.index.add([filename])
		commit = repo.index.commit("", parent_commits=parent_commits)
		repo.remotes.origin.push(refspec=refspec)
		return commit


class RedisTestMixin(BaseTestMixin):
	def _start_redis(self):
		self._redis_process = subprocess.Popen(
			["redis-server", REDISCONF],
			stderr=subprocess.PIPE,
			stdout=subprocess.PIPE)

		while True:
			self._redis_process.poll()
			if self._redis_process.returncode is not None:
				print self._redis_process.communicate()
				assert False
			assert self._redis_process.returncode is None
			line = self._redis_process.stdout.readline()
			if line.find("The server is now ready to accept connections") != -1:
				break

	def _stop_redis(self):
		redis_conn = ConnectionFactory.get_redis_connection()
		redis_conn.flushdb()
		self._redis_process.terminate()
