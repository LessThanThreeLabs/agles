from nose.tools import *

from database.engine import ConnectionFactory
from database.schema import *
from model_server.build_outputs import ConsoleType
from model_server.build_outputs.update_handler import BuildOutputsUpdateHandler, REDIS_SUBTYPE_KEY, REDIS_TYPE_KEY
from util.permissions import RepositoryPermissions
from util.test import BaseIntegrationTest
from util.test.mixins import RedisTestMixin


class BuildsUpdateHandlerTest(BaseIntegrationTest, RedisTestMixin):
	def setUp(self):
		super(BuildsUpdateHandlerTest, self).setUp()
		self._start_redis()

	def tearDown(self):
		super(BuildsUpdateHandlerTest, self).tearDown()
		self._stop_redis()

	def _initialize(self):
		with ConnectionFactory.get_sql_connection() as sqlconn:
			ins_user = user.insert().values(
				email='a',
				first_name='a',
				last_name='a',
				password_hash='a',
				salt='a'*16
			)

			user_id = sqlconn.execute(ins_user).inserted_primary_key[0]

			ins_repostore = repostore.insert().values(
				uri='a', host_name='a', repositories_path='a')

			repostore_id = sqlconn.execute(ins_repostore).inserted_primary_key[0]

			ins_repo = repo.insert().values(
				name='a',
				hash='a',
				repostore_id=repostore_id,
				default_permissions=RepositoryPermissions.RWA
			)

			repo_id = sqlconn.execute(ins_repo).inserted_primary_key[0]

			ins_commit = commit.insert().values(
				repo_hash='a',
				user_id=user_id,
				message='a',
				timestamp=1,
			)

			commit_id = sqlconn.execute(ins_commit).inserted_primary_key[0]

			ins_change = change.insert().values(
				commit_id=commit_id,
				merge_target='a',
				number=1,
				status='a',
				start_time=1,
				end_time=1
			)

			change_id = sqlconn.execute(ins_change).inserted_primary_key[0]

			ins_build = build.insert().values(
				change_id=change_id,
				is_primary=True,
				status='a',
				start_time=1,
				end_time=1
			)

			self.build_ids = []
			for i in xrange(10):
				self.build_ids.append(sqlconn.execute(ins_build).inserted_primary_key[0])

	def console_append_test(self):
		self._initialize()
		update_handler = BuildOutputsUpdateHandler()

		compile_line_dict = {}
		test_line_dict = {}
		build_general = []
		build_setup = []
		for i in self.build_ids:
			update_handler.init_subtypes(i, ConsoleType.Compile, ["compile"])
			update_handler.init_subtypes(i, ConsoleType.Test, ["unittest"])

			line_compile = "build:1, line:%s, console:compile" % i
			build_general.append(line_compile)
			line_test = "build:1, line:%s, console:test" % i
			build_setup.append(line_test)
			update_handler.append_console_line(1, i, line_compile,
				type=ConsoleType.Compile, subtype="compile")
			compile_line_dict[str(i)] = line_compile
			update_handler.append_console_line(1, i, line_test,
				type=ConsoleType.Test, subtype="unittest")
			test_line_dict[str(i)] = line_test
