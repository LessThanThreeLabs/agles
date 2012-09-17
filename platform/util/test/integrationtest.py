import unittest

from database import schema


class BaseIntegrationTest(unittest.TestCase):
	def setUp(self):
		super(BaseIntegrationTest, self).setUp()
		schema.reseed_db()

	def tearDown(self):
		super(BaseIntegrationTest, self).tearDown()
		schema.reseed_db()
