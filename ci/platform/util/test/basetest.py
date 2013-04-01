import eventlet

import settings.log
import unittest

from database import schema


class Timeout(object):
	def __init__(self, time):
		self.time = time

	def __call__(self, func):
		def test_timeout_func(*args):
			try:
				with eventlet.timeout.Timeout(self.time):
					return func(*args)
			except eventlet.timeout.Timeout:
				assert False
		return test_timeout_func


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
