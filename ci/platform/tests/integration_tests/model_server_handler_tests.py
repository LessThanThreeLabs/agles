from nose.tools import *

from database.engine import ConnectionFactory
from database.schema import *
from model_server.build_consoles import ConsoleType
from model_server.build_consoles.update_handler import BuildConsolesUpdateHandler
from model_server.changes.read_handler import ChangesReadHandler
from util.test import BaseIntegrationTest


class BuildsUpdateHandlerTest(BaseIntegrationTest):
	def setUp(self):
		super(BuildsUpdateHandlerTest, self).setUp()

	def tearDown(self):
		super(BuildsUpdateHandlerTest, self).tearDown()

	def _initialize(self):
		with ConnectionFactory.get_sql_connection() as sqlconn:
			ins_user = user.insert().values(
				email='a',
				first_name='first',
				last_name='last',
				password_hash='a',
				salt='a' * 16
			)

			self.user_id = sqlconn.execute(ins_user).inserted_primary_key[0]

			ins_repostore = repostore.insert().values(
				host_name='a', repositories_path='a')

			repostore_id = sqlconn.execute(ins_repostore).inserted_primary_key[0]

			ins_repo = repo.insert().values(
				name='a',
				uri='a',
				repostore_id=repostore_id,
				forward_url="forwardurl",
				privatekey="privatekey",
				publickey="publickey",
				created=1234
			)

			self.repo_id = sqlconn.execute(ins_repo).inserted_primary_key[0]

			ins_commit = commit.insert().values(
				repo_id=self.repo_id,
				user_id=self.user_id,
				message='a',
				timestamp=1,
			)

			commit_id = sqlconn.execute(ins_commit).inserted_primary_key[0]

			ins_change = change.insert().values(
				commit_id=commit_id,
				repo_id=self.repo_id,
				merge_target='a',
				number=1,
				status='a',
				start_time=1,
				end_time=1
			)

			change_id = sqlconn.execute(ins_change).inserted_primary_key[0]

			ins_build = build.insert().values(
				change_id=change_id,
				repo_id=self.repo_id,
				is_primary=True,
				status='a',
				start_time=1,
				end_time=1
			)

			self.build_ids = []
			for i in xrange(3):
				self.build_ids.append(sqlconn.execute(ins_build).inserted_primary_key[0])

	def console_append_test(self):
		self._initialize()
		update_handler = BuildConsolesUpdateHandler()

		for i in self.build_ids:
			update_handler.add_subtypes(i, ConsoleType.Setup, ["setup"])
			update_handler.add_subtypes(i, ConsoleType.Compile, ["compile"])
			update_handler.add_subtypes(i, ConsoleType.Test, ["unittest"])

			test_lines = {}
			for line_num in range(1, 3):
				update_handler.append_console_lines(i, {1: "build:%s, line:1, console:setup, (%s)" % (i, line_num)},
					type=ConsoleType.Setup, subtype="setup")
				compile_line = "build:%s, line:%s, console:compile" % (i, line_num)
				update_handler.append_console_lines(i, {line_num: compile_line},
					type=ConsoleType.Compile, subtype="compile")
				test_lines[line_num] = "build:%s, line:%s, console:test" % (i, line_num)
			update_handler.append_console_lines(i, test_lines,
				type=ConsoleType.Test, subtype="unittest")

	def query_all_changes_test(self):
		self._initialize()
		read_handler = ChangesReadHandler()
		results = read_handler.query_changes(self.user_id, self.repo_id, "all", ["first"], 0, 100)
		assert_equal(len(results), 1)
		results = read_handler.query_changes(self.user_id, self.repo_id, "all", ["last"], 0, 100)
		assert_equal(len(results), 1)
		results = read_handler.query_changes(self.user_id, self.repo_id, "all", ["first", "last"], 0, 100)
		assert_equal(len(results), 1)
		results = read_handler.query_changes(self.user_id, self.repo_id, "all", ["no match"], 0, 100)
		assert_equal(len(results), 0)

	def query_user_changes_test(self):
		self._initialize()
		read_handler = ChangesReadHandler()
		results = read_handler.query_changes(self.user_id, self.repo_id, "me", ["first"], 0, 100)
		assert_equal(len(results), 1)
		results = read_handler.query_changes(self.user_id, self.repo_id, "me", ["last"], 0, 100)
		assert_equal(len(results), 1)
		results = read_handler.query_changes(self.user_id, self.repo_id, "me", ["first", "last"], 0, 100)
		assert_equal(len(results), 1)
		results = read_handler.query_changes(self.user_id, self.repo_id, "me", ["no match"], 0, 100)
		assert_equal(len(results), 0)

		fake_user_id = self.user_id + 1
		results = read_handler.query_changes(fake_user_id, self.repo_id, "me", ["first"], 0, 100)
		assert_equal(len(results), 0)
		results = read_handler.query_changes(fake_user_id, self.repo_id, "me", ["last"], 0, 100)
		assert_equal(len(results), 0)
		results = read_handler.query_changes(fake_user_id, self.repo_id, "me", ["first", "last"], 0, 100)
		assert_equal(len(results), 0)
