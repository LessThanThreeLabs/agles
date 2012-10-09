import unittest

from nose.tools import *

from database.engine import ConnectionFactory
from model_server.build.update_handler import BuildUpdateHandler, Console
from util.test.mixins import RedisTestMixin


class BuildUpdateHandlerTest(unittest.TestCase, RedisTestMixin):
	def setUp(self):
		super(BuildUpdateHandlerTest, self).setUp()
		self._start_redis()

	def tearDown(self):
		super(BuildUpdateHandlerTest, self).tearDown()
		self._stop_redis()

	def console_append_test(self):
		update_handler = BuildUpdateHandler()

		build_stdout = []
		build_stderr = []
		for i in xrange(10):
			line_stdout = "build:1, line:%s, console:stdout" % i
			build_stdout.append(line_stdout)
			line_stderr = "build:1, line:%s, console:stderr" % i
			build_stderr.append(line_stderr)
			update_handler.append_console_output(1, line_stdout)
			update_handler.append_console_output(1, line_stderr,
				console=Console.Stderr)

		self._assert_console_output_equal(1, '\n'.join(build_stdout), Console.Stdout)
		self._assert_console_output_equal(1, '\n'.join(build_stderr), Console.Stderr)

	def _assert_console_output_equal(self, build_id, expected_output,
									 console_type):
		key = "build.output:%s:%s" % (build_id, console_type)
		redis_conn = ConnectionFactory.get_redis_connection()
		actual_output = '\n'.join(redis_conn.lrange(key, 0, -1))
		assert_equal(expected_output, actual_output,
			msg="Console output for key %s not what expected" % key)
