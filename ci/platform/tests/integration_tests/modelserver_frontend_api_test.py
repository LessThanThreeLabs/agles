'''
--USERS--

# will return an error if email is already in use
x - user_id : int = create(email, passwordHash, information)

# throws error if no user found
x - userId : int = getUserId(email, passwordHash)
x - user : dict = getUser(email, passwordHash)
x - user : dict = getUserFromId(userId)


--REPOSITORIES--

# throws error if invalid user
# can return empty list if no repositories for user
x - repositoryIds[] : int = getWritableRepoIds(userId)
x - repositories[] : dict = getWritableRepos(userId)
x - repository : dict = getRepoFromId(userId, repositoryId)


--BUILDS--

# returns build of buildId
x - build = getFromId(userId, buildId)

# returns builds [startIndex, endIndex) of type
#   if endIndexExclusive?, goes until end
x - builds[] = getRange(userId, repositoryId, type, startIndexInclusive, endIndexExclusive)


--BUILD OUTPUTS--

# returns array of lines (might be smarter way of doing this...)
buildCompileLines[] : dict = getCompilationOutput(userId, buildId)
buildTestLines[] : dict = getTestOutput(userId, buildId)
<more to be added>
'''
import database

from hashlib import sha512

from nose.tools import *

from database.engine import ConnectionFactory
from util.permissions import RepositoryPermissions
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from model_server import ModelServer


class ModelServerFrontEndApiTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):

	EMAIL = "jchu@lt3.com"
	REPO_NAME = "r"

	def setUp(self):
		super(ModelServerFrontEndApiTest, self).setUp()
		self._purge_queues()
		self._start_model_server()
		self._create_user()
		self._create_repo()

	def tearDown(self):
		super(ModelServerFrontEndApiTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

###################
#	USERS
###################

	def _create_user(self):
		self.password_hash = sha512().hexdigest()
		with ModelServer.rpc_connect("users", "create") as conn:
			self.user_info = {
				"email": self.EMAIL,
				"first_name": "asdf",
				"last_name": "bdsf",
				"salt": "a"*16,
				"password_hash": self.password_hash
			}
			self.user_id = conn.create_user(self.user_info)

	def _assert_dict_subset(self, expected, actual):
		for key in expected.iterkeys():
			assert_equals(expected[key], actual[key])


	def test_get_user_id(self):
		with ModelServer.rpc_connect("users", "read") as conn:
			user_id = conn.get_user_id(self.EMAIL, self.password_hash)
		assert_equals(self.user_id, user_id)


	def test_get_user(self):
		with ModelServer.rpc_connect("users", "read") as conn:
			user = conn.get_user(self.EMAIL, self.password_hash)
		self._assert_dict_subset(self.user_info, user)

	def test_get_user_from_id(self):
		with ModelServer.rpc_connect("users", "read") as conn:
			user = conn.get_user_from_id(self.user_id)
		self._assert_dict_subset(self.user_info, user)

#####################
#	REPOS
#####################

# TODO: FIX ALL OF THIS BELOW. THIS IS ALL HAX

	def _create_repo(self):
		repostore = database.schema.repostore
		permission = database.schema.permission
		repo = database.schema.repo

		repostore_ins = repostore.insert().values(uri="http://machine0", host_name="localhost", repositories_path="/tmp")

		with ConnectionFactory.get_sql_connection() as conn:
			result = conn.execute(repostore_ins)
			self.repostore_id = result.inserted_primary_key[0]

		with ModelServer.rpc_connect("repos", "create") as conn:
			self.repo_id = conn._create_repo_in_db(self.REPO_NAME, self.REPO_NAME, "http://machine0", RepositoryPermissions.RW)

		with ConnectionFactory.get_sql_connection() as conn:
			query = repo.select().where(repo.c.id==self.repo_id)
			row = conn.execute(query).first()
			self.repo_hash = row[repo.c.hash]
			permission_ins = permission.insert().values(user_id=self.user_id, repo_hash=self.repo_hash, permissions=RepositoryPermissions.RW)
			conn.execute(permission_ins)

	def test_get_writable_repo_ids(self):
		with ModelServer.rpc_connect("repos", "read") as conn:
			writable_repo_ids = conn.get_writable_repo_ids(self.user_id)
		assert_in(self.repo_id, writable_repo_ids)

	def test_get_writable_repos(self):
		with ModelServer.rpc_connect("repos", "read") as conn:
			writable_repos = conn.get_writable_repos(self.user_id)
		repo = list(writable_repos).pop()
		assert_equals(self.repo_id, repo["id"])
		assert_equals(self.REPO_NAME, repo["name"])
		assert_equals(self.repo_hash, repo["hash"])
		assert_equals(self.repostore_id, repo["repostore_id"])
		assert_equals(RepositoryPermissions.RW, repo["default_permissions"])

	def test_get_repo_from_id(self):
		with ModelServer.rpc_connect("repos", "read") as conn:
			repo = conn.get_repo_from_id(self.user_id, self.repo_id)
		assert_equals(self.repo_id, repo["id"])
		assert_equals(self.REPO_NAME, repo["name"])
		assert_equals(self.repo_hash, repo["hash"])
		assert_equals(self.repostore_id, repo["repostore_id"])
		assert_equals(RepositoryPermissions.RW, repo["default_permissions"])
