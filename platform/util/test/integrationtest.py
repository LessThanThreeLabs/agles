import unittest

from database import schema


class BaseIntegrationTest(unittest.TestCase):
	def setUp(self):
		schema.reseed_db()

	def tearDown(self):
		schema.reseed_db()
