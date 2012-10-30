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
from hashlib import sha512

from nose.tools import *

from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from model_server import ModelServer


class ModelServerFrontEndApiTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):

	EMAIL = "jchu@lt3.com"

	def setUp(self):
		super(ModelServerFrontEndApiTest, self).setUp()
		self._purge_queues()
		self._start_model_server()
		self._create_user()

	def tearDown(self):
		super(ModelServerFrontEndApiTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

###################
#	USERS
###################

	def _create_user(self):
		with ModelServer.rpc_connect("users", "create") as conn:
			self.user_info = {
				"email": self.EMAIL,
				"name": "asdf",
				"salt": "a"*16
			}
			self.password_hash = sha512().digest()
			self.user_id = conn.create_user(self.password_hash, self.user_info)

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

