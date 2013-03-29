import settings.log
import unittest

from database import schema


class BaseTest(unittest.TestCase):
	@classmethod
	def setup_class(cls):
		settings.log.configure()

	@classmethod
	def teardown_class(cls):
		pass


class BaseUnitTest(BaseTest):
	pass


class BaseIntegrationTest(BaseTest):
	@classmethod
	def setup_class(cls):
		super(BaseIntegrationTest, cls).setup_class()
		schema.reseed_db()

	def tearDown(self):
		super(BaseIntegrationTest, self).tearDown()
		schema.reseed_db()
