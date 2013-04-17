import eventlet
import os
import shutil
import subprocess

from nose.tools import *
from util import greenlets
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin, RedisTestMixin

TEST_REPO_ROOT = '/tmp'


class StartServerTests(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin, RedisTestMixin):

	@classmethod
	def setup_class(cls):
		super(StartServerTests, cls).setup_class()
		cls._purge_queues()
		cls._start_redis()
		cls._start_model_server()
		cls.repodir = os.path.join(TEST_REPO_ROOT, 'repositories')
		shutil.rmtree(cls.repodir, ignore_errors=True)
		os.mkdir(cls.repodir)

	@classmethod
	def teardown_class(cls):
		super(StartServerTests, cls).teardown_class()
		shutil.rmtree(cls.repodir)

		cls._stop_model_server()
		cls._stop_redis()
		cls._purge_queues()

	def test_start_repo_server(self):

		def start_model_server():
			start_model_server_p = subprocess.Popen(["bin/start_model_server.py"])
			eventlet.sleep(5)
			retcode = start_model_server_p.poll()
			try:
				start_model_server_p.terminate()
			except:
				return False
			return retcode is None

		def start_filesystem_repo_server():
			start_filesystem_repo_server_p = subprocess.Popen(["bin/start_filesystem_repo_server.py", "-r", self.repodir])
			eventlet.sleep(5)
			retcode = start_filesystem_repo_server_p.poll()
			try:
				start_filesystem_repo_server_p.terminate()
			except:
				return False
			return retcode is None

		def start_verification_server():
			start_verification_server_p = subprocess.Popen(["bin/start_verification_server.py", "-t", "mock"])
			eventlet.sleep(5)
			retcode = start_verification_server_p.poll()
			try:
				start_verification_server_p.terminate()
			except:
				return False
			return retcode is None

		def start_license_server():
			start_license_server_p = subprocess.Popen(["bin/start_license_server.py"])
			eventlet.sleep(5)
			retcode = start_license_server_p.poll()
			try:
				start_license_server_p.terminate()
			except:
				return False
			return retcode is None
		errors = []
		model_server_thread = eventlet.spawn(start_model_server)
		repo_server_thread = eventlet.spawn(start_filesystem_repo_server)
		verification_server_thread = eventlet.spawn(start_verification_server)
		license_server_thread = eventlet.spawn(start_license_server)

		if not model_server_thread.wait():
			errors.append("model server startup failed")
		if not repo_server_thread.wait():
			errors.append("repo server startup failed")
		if not verification_server_thread.wait():
			errors.append("verification server startup failed")
		if not license_server_thread.wait():
			errors.append("license server startup failed")

		assert_equal(len(errors), 0, errors)
