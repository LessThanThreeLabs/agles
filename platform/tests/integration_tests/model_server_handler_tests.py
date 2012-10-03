from datetime import datetime

from nose.tools import *

from database.engine import ConnectionFactory
from database.schema import build, build_console
from model_server.build.update_handler import BuildConsoleUpdateHandler, Console
from util.test import BaseIntegrationTest
from util.test.mixins import RedisTestMixin

# We currently have commented out this test until we have the ability to create
# builds without foreign key errors.

"""
class BuildUpdateHandlerTest(BaseIntegrationTest, RedisTestMixin):
	def setUp(self):
		super(BuildUpdateHandlerTest, self).setUp()
		self._start_redis()
		# TODO(jchu): When jpotter gets his crap together, use the actual create method
		ins = build.insert().values(commit_id=1, number=1, status='done',
			start_time=datetime.now(), end_time=datetime.now())
		sql_conn = ConnectionFactory.get_sql_connection()
		try:
			self.build_id = sql_conn.execute(ins).inserted_primary_key
		finally:
			sql_conn.close()

	def tearDown(self):
		super(BuildUpdateHandlerTest, self).tearDown()
		self._stop_redis()

	def console_flush_test(self):
		update_handler = BuildConsoleUpdateHandler()

		build_stdout = []
		build_stderr = []
		for i in xrange(10):
			line_stdout = "build:1, line:%s, console:stdout" % i
			build_stdout.append(line_stdout)
			line_stderr = "build:1, line:%s, console:stderr" % i
			build_stderr.append(line_stderr)
			update_handler.append_console_output(self.build_id, line_stdout)
			update_handler.append_console_output(self.build_id, line_stderr,
				console=Console.Stderr)

		update_handler.flush_console_output(self.build_id, console=Console.Stdout)
		update_handler.flush_console_output(self.build_id, console=Console.Stderr)

		self._assert_db_console_output_equals(self.build_id, build_stdout, Console.Stdout)
		self._assert_db_console_output_equals(self.build_id, build_stderr, Console.Stderr)

	def _assert_db_console_output_equals(self, build_id, expected, console):
		query = build_console.select().where(build_console.c.build_id==build_id,
			build_console.c.type==console)
		sql_conn = ConnectionFactory.get_sql_connection()
		row = sql_conn.execute(query).fetchone()
		assert_equals(expected, row[build_console.c.console_output],
			msg="DB and expected console output do not match")
"""