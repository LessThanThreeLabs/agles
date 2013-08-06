""" mixins.py - contains test mixins

This module contains all mixins meant to be used for unit testing.

Mixins are NOT meant to be instantiated and should never be instantiated.
Instantiating a mixin violates the mixin paradigm and will have unintended side
consequences/side effects.
"""
import os
import subprocess

import eventlet

from database.engine import ConnectionFactory

FILEDIR = os.path.dirname(os.path.realpath(__file__))
REDISCONF = os.path.join(FILEDIR, '..', '..', 'conf', 'redis', 'platform_redis.conf')


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
		except eventlet.greenlet.GreenletExit:
			pass

	@classmethod
	def _with_new_engine(cls, method):
		def wrapped_method(*args, **kwargs):
			ConnectionFactory.recreate_engine()
			method(*args, **kwargs)
		return wrapped_method


class ModelServerTestMixin(BaseTestMixin):
	"""Mixin for integration tests that require a running model server"""

	@classmethod
	def _start_model_server(cls, license_verifier=True):
		from model_server.model_server import ModelServer
		cls.model_server_greenlet = ModelServer().start(license_verifier=license_verifier)

	@classmethod
	def _stop_model_server(cls):
		cls.model_server_greenlet.kill()
		try:
			cls.model_server_greenlet.wait()
		except eventlet.greenlet.GreenletExit:
			pass


class RabbitMixin(BaseTestMixin):
	@classmethod
	def _purge_queues(cls):
		from settings.rabbit import RabbitSettings
		command = """rabbitmqadmin -u %s -p %s -f tsv -q list queues name messages|
			while read queue count;
			do if [ ${count:-1} -gt "0" ];
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
		commit = repo.index.commit("Updated %s" % filename, parent_commits=parent_commits)
		repo.remotes.origin.push(refspec=refspec)
		return commit


class RedisTestMixin(BaseTestMixin):
	@classmethod
	def _start_redis(cls):
		cls._stop_redis()
		cls._redis_process = subprocess.Popen(
			["redis-server", REDISCONF],
			stderr=subprocess.PIPE,
			stdout=subprocess.PIPE)

		while True:
			cls._redis_process.poll()
			if cls._redis_process.returncode is not None:
				print cls._redis_process.communicate()
				assert False
			assert cls._redis_process.returncode is None
			line = cls._redis_process.stdout.readline()
			if line.find("The server is now ready to accept connections") != -1:
				break

	@classmethod
	def _stop_redis(cls):
		try:
			for redis_type in ('repostore', 'virtual_machine'):
				redis_conn = ConnectionFactory.get_redis_connection(redis_type)
				redis_conn.flushdb()
			cls._redis_process.terminate()
		except:
			redis_cmd = 'redis-server.*%s' % os.path.basename(REDISCONF)
			subprocess.call('pgrep -f %s | xargs kill -9' % redis_cmd, shell=True)
