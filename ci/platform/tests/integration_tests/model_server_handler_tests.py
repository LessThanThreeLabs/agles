import unittest

from nose.tools import *
from sqlalchemy import and_

from database.engine import ConnectionFactory
from database.schema import *
from model_server.build_outputs.update_handler import BuildOutputsUpdateHandler, Console, REDIS_KEY_TEMPLATE
from util.test import BaseIntegrationTest
from util.test.mixins import RedisTestMixin


class BuildsUpdateHandlerTest(BaseIntegrationTest, RedisTestMixin):
	def setUp(self):
		super(BuildsUpdateHandlerTest, self).setUp()
		self._start_redis()

	def tearDown(self):
		super(BuildsUpdateHandlerTest, self).tearDown()
		self._stop_redis()

	def console_append_test(self):
		update_handler = BuildOutputsUpdateHandler()

		gen_line_dict = {}
		setup_line_dict = {}
		build_general = []
		build_setup = []
		for i in xrange(10):
			line_general = "build:1, line:%s, console:general" % i
			build_general.append(line_general)
			line_setup = "build:1, line:%s, console:setup" % i
			build_setup.append(line_setup)
			update_handler.append_console_line(1, i, line_general)
			gen_line_dict[str(i)] = line_general
			update_handler.append_console_line(1, i, line_setup,
				console=Console.Setup, subcategory="unittest")
			setup_line_dict[str(i)] = line_setup

		self._assert_console_output_equal(1, gen_line_dict, Console.General)
		self._assert_console_output_equal(1, setup_line_dict, Console.Setup, "unittest")

	def console_flush_test(self):
		update_handler = BuildOutputsUpdateHandler()
		lines = []
		for i in xrange(11):
			line = str(i)
			update_handler.append_console_line(1, i, line)
			lines.append(line)

		output = '\n'.join(lines)
		redis_key = REDIS_KEY_TEMPLATE % (1, Console.General, '')
		db_output = update_handler._compact_output(
			ConnectionFactory.get_redis_connection(),redis_key)
		assert_equal(output, db_output)

	def _assert_console_output_equal(self, build_id, expected_output,
									 console_type, subcategory=""):
		key = REDIS_KEY_TEMPLATE % (build_id, console_type, subcategory)
		redis_conn = ConnectionFactory.get_redis_connection()
		actual_output = redis_conn.hgetall(key)
		assert_equal(expected_output, actual_output,
			msg="Console output for key %s not what expected" % key)
