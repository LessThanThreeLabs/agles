import settings.log
import unittest

from database import schema


class BaseTest(unittest.TestCase):
	@classmethod
	def setup_class(cls):
		settings.log.configure()


class BaseUnitTest(BaseTest):
	pass


class BaseIntegrationTest(BaseTest):
	def setUp(self):
		super(BaseIntegrationTest, self).setUp()
		schema.reseed_db()

	def tearDown(self):
		super(BaseIntegrationTest, self).tearDown()
		schema.reseed_db()
