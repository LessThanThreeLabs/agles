from nose.tools import *

from database.engine import ConnectionFactory
from database.schema import *
from model_server.build_outputs import ConsoleType
from model_server.build_outputs.update_handler import BuildOutputsUpdateHandler, REDIS_SUBTYPE_KEY, REDIS_TYPE_KEY
from util.test import BaseIntegrationTest
from util.test.mixins import RedisTestMixin


class BuildsUpdateHandlerTest(BaseIntegrationTest, RedisTestMixin):
	def setUp(self):
		super(BuildsUpdateHandlerTest, self).setUp()
		self._start_redis()

	def tearDown(self):
		super(BuildsUpdateHandlerTest, self).tearDown()
		self._stop_redis()

	def init_subtypes_test(self):
		build_id = 1
		type = ConsoleType.Setup
		subtypes = ['sub1', 'sub2', 'sub3']

		update_hander = BuildOutputsUpdateHandler()
		update_hander.init_subtypes(build_id, type, subtypes)

		redis_conn = ConnectionFactory.get_redis_connection()
		type_key = REDIS_TYPE_KEY % (build_id, type)
		def check_subtype(subtype):
			subtype_key = REDIS_SUBTYPE_KEY % (build_id, type, subtype)
			priority = redis_conn.hget(type_key, subtype_key)
			assert_equals(priority, subtypes.index(subtype))

	def console_append_test(self):
		update_handler = BuildOutputsUpdateHandler()

		compile_line_dict = {}
		test_line_dict = {}
		build_general = []
		build_setup = []
		for i in xrange(10):
			line_compile = "build:1, line:%s, console:compile" % i
			build_general.append(line_compile)
			line_test = "build:1, line:%s, console:test" % i
			build_setup.append(line_test)
			update_handler.append_console_line(1, i, line_compile,
				type=ConsoleType.Compile)
			compile_line_dict[str(i)] = line_compile
			update_handler.append_console_line(1, i, line_test,
				type=ConsoleType.Test, subtype="unittest")
			test_line_dict[str(i)] = line_test

		self._assert_console_output_equal(1, compile_line_dict, ConsoleType.Compile)
		self._assert_console_output_equal(1, test_line_dict, ConsoleType.Test, "unittest")

	def console_flush_test(self):
		update_handler = BuildOutputsUpdateHandler()
		lines = []
		for i in xrange(11):
			line = str(i)
			update_handler.append_console_line(1, i, line, ConsoleType.Setup)
			lines.append(line)

		output = '\n'.join(lines)
		redis_key = REDIS_SUBTYPE_KEY % (1, ConsoleType.Setup, '')
		db_output = update_handler._compact_output(
			ConnectionFactory.get_redis_connection(),
			1,
			ConsoleType.Setup,
			'')
		assert_equal(output, db_output)

	def _assert_console_output_equal(self, build_id, expected_output,
									 type, subtype=""):
		key = REDIS_SUBTYPE_KEY % (build_id, type, subtype)
		redis_conn = ConnectionFactory.get_redis_connection()
		actual_output = redis_conn.hgetall(key)
		assert_equal(expected_output, actual_output,
			msg="Console output for key %s not what expected" % key)
