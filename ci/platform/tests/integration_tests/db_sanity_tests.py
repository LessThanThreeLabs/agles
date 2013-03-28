from nose.tools import *
from util.test import BaseIntegrationTest
from util.test import fake_data_generator


class DbSanityCheck(BaseIntegrationTest):
	def setUp(self):
		super(BaseIntegrationTest, self).setUp()

	def tearDown(self):
		super(BaseIntegrationTest, self).setUp()

	def test_data_generator(self):
		generator = fake_data_generator.SchemaDataGenerator()
		generator.generate(num_repos=1, num_repo_stores=1, num_users=1, num_commits=1)
