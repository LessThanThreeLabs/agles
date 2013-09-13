from nose.tools import *

from database.engine import ConnectionFactory
from database.schema import *
from model_server.build_consoles import ConsoleType
from model_server.build_consoles.update_handler import BuildConsolesUpdateHandler
from model_server.build_consoles.read_handler import BuildConsolesReadHandler
from model_server.changes.read_handler import ChangesReadHandler
from model_server.changes.create_handler import ChangesCreateHandler
from util.test import BaseIntegrationTest


class ModelServerHandlerTest(BaseIntegrationTest):
	def setUp(self):
		super(ModelServerHandlerTest, self).setUp()
		self._initialize()

	def _initialize(self):
		with ConnectionFactory.get_sql_connection() as sqlconn:
			ins_user = user.insert().values(
				email='a',
				first_name='first',
				last_name='LaSt',
				password_hash='a',
				salt='a' * 16,
				created=0,
			)

			self.user_id = sqlconn.execute(ins_user).inserted_primary_key[0]

			ins_repostore = repostore.insert().values(
				ip_address='127.0.0.1', repositories_path='a')

			repostore_id = sqlconn.execute(ins_repostore).inserted_primary_key[0]

			ins_repo = repo.insert().values(
				name='a',
				uri='a',
				repostore_id=repostore_id,
				forward_url="forwardurl",
				created=1234,
				type='git'
			)

			self.repo_id = sqlconn.execute(ins_repo).inserted_primary_key[0]

			self.commit_sha = '0123456789abcdef'
			self.commit_owner = "Max Power"
			self.commit_email = "MaxPower's email"

			ins_commit = commit.insert().values(
				repo_id=self.repo_id,
				user_id=self.user_id,
				message='a',
				sha=self.commit_sha,
				timestamp=1,
				committer_name=self.commit_owner,
				committer_email=self.commit_email
			)

			commit_id = sqlconn.execute(ins_commit).inserted_primary_key[0]

			ins_change = change.insert().values(
				commit_id=commit_id,
				repo_id=self.repo_id,
				merge_target='a',
				number=1,
				verification_status='a',
				create_time=1,
				start_time=1,
				end_time=1
			)

			self.change_id = sqlconn.execute(ins_change).inserted_primary_key[0]

			ins_build = build.insert().values(
				commit_id=commit_id,
				change_id=self.change_id,
				repo_id=self.repo_id,
				status='a',
				create_time=1,
				start_time=1,
				end_time=1
			)

			self.build_ids = []
			for i in xrange(3):
				self.build_ids.append(sqlconn.execute(ins_build).inserted_primary_key[0])

	def test_console_append(self):
		update_handler = BuildConsolesUpdateHandler()

		for i in self.build_ids:
			update_handler.add_subtype(i, ConsoleType.Setup, "setup")
			update_handler.add_subtype(i, ConsoleType.Compile, "compile")
			update_handler.add_subtype(i, ConsoleType.TestFactory, "my factory")
			update_handler.add_subtype(i, ConsoleType.Test, "unittest")

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

	def test_store_xunit_contents(self):
		update_handler = BuildConsolesUpdateHandler()

		for i in self.build_ids:
			update_handler.add_subtype(i, ConsoleType.Test, "unittest")
			update_handler.store_xunit_contents(i, ConsoleType.Test, "unittest",
				{"file": "contents1", "file2": "contents2"})

	def test_store_patch(self):
		create_handler = ChangesCreateHandler()
		create_handler.store_patch(self.change_id, "contents")

	def test_query_changes_group(self):
		read_handler = ChangesReadHandler()
		results = read_handler.query_changes_group(self.user_id, [self.repo_id], "all", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_group(self.user_id, [self.repo_id], "me", 0, 100)
		assert_equal(1, len(results))

		results = read_handler.query_changes_group(self.user_id, [self.repo_id + 1, self.repo_id + 2], "me", 0, 100)
		assert_equal(0, len(results))

		results = read_handler.query_changes_group(self.user_id, [self.repo_id, self.repo_id + 1], "me", 0, 100)
		assert_equal(1, len(results))

		fake_user_id = self.user_id + 1
		results = read_handler.query_changes_group(fake_user_id, [self.repo_id], "me", 0, 100)
		assert_equal(0, len(results))

	def test_query_changes_filter_empty_input(self):
		read_handler = ChangesReadHandler()
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [], "", 0, 100)
		assert_equal(0, len(results))

	def test_query_changes_filter(self):
		read_handler = ChangesReadHandler()
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "first", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "last", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "laST", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "first last", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "no match", 0, 100)
		assert_equal(0, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], self.commit_sha, 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], self.commit_sha[:4], 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], self.commit_sha[4:], 0, 100)
		assert_equal(0, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "garbage and fIRSt", 0, 100)
		assert_equal(1, len(results))
		results = read_handler.query_changes_filter(self.user_id, [self.repo_id], "%s and garbage" % self.commit_sha[:7], 0, 100)
		assert_equal(1, len(results))


	def _create_lines(self, build_id, type, subtype):
		update_handler = BuildConsolesUpdateHandler()

		update_handler.add_subtype(build_id, ConsoleType.Setup, "setup")
		update_handler.add_subtype(build_id, ConsoleType.Compile, "compile")
		update_handler.add_subtype(build_id, ConsoleType.TestFactory, "my factory")
		update_handler.add_subtype(build_id, ConsoleType.Test, "unittest")

		test_lines = {}
		for line_num in range(5):
			test_lines[line_num] = "build:%s, line:%s, console:test" % (build_id, line_num)
		update_handler.append_console_lines(build_id, test_lines, type=type, subtype=subtype)
		for line_num in range(5):
			test_lines[line_num] = "second line"
		update_handler.append_console_lines(build_id, test_lines, type=type, subtype=subtype)

	def test_get_output_lines_multi_number(self):
		self._create_lines(self.build_ids[0], ConsoleType.Test, 'unittest')

		read_handler = BuildConsolesReadHandler()
		build_console_id = read_handler.get_build_console_id(self.user_id, self.build_ids[0], ConsoleType.Test, 'unittest')
		lines = read_handler.get_output_lines(self.user_id, build_console_id)

		for line in lines.itervalues():
			assert_equal(line, "second line")
