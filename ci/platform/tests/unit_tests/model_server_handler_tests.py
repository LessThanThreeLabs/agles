import unittest

from nose.tools import *

from database.engine import ConnectionFactory
from model_server.build_outputs.update_handler import BuildOutputsUpdateHandler, Console
from util.test.mixins import RedisTestMixin


class BuildsUpdateHandlerTest(unittest.TestCase, RedisTestMixin):
	def setUp(self):
		super(BuildsUpdateHandlerTest, self).setUp()
		self._start_redis()

	def tearDown(self):
		super(BuildsUpdateHandlerTest, self).tearDown()
		self._stop_redis()

	def console_append_test(self):
		update_handler = BuildOutputsUpdateHandler()

		build_general = []
		build_setup = []
		for i in xrange(10):
			line_general = "build:1, line:%s, console:general" % i
			build_general.append(line_general)
			line_setup = "build:1, line:%s, console:setup" % i
			build_setup.append(line_setup)
			update_handler.append_console_output(1, line_general)
			update_handler.append_console_output(1, line_setup,
				console=Console.Setup)

		self._assert_console_output_equal(1, '\n'.join(build_general), Console.General)
		self._assert_console_output_equal(1, '\n'.join(build_setup), Console.Setup)

	def _assert_console_output_equal(self, build_id, expected_output,
									 console_type):
		key = "build.output:%s:%s" % (build_id, console_type)
		redis_conn = ConnectionFactory.get_redis_connection()
		actual_output = '\n'.join(redis_conn.lrange(key, 0, -1))
		assert_equal(expected_output, actual_output,
			msg="Console output for key %s not what expected" % key)
