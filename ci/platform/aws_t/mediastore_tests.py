
from nose.tools import *

from database.engine import ConnectionFactory
from model_server.mediastore import S3MediaStore
from settings.test.aws.s3 import TestS3Settings
from util.test import BaseIntegrationTest


class S3MediaStoreTest(BaseIntegrationTest):
	def setUp(self):
		self.path = "test/this/path"
		self.binary = '0b01010101010010101'
		self.mediastore = S3MediaStore(TestS3Settings.media_bucket)
		super(S3MediaStoreTest, self).setUp()

	def tearDown(self):
		bucket = ConnectionFactory.get_s3_bucket(TestS3Settings.media_bucket)
		for key in bucket.list():
			bucket.delete_key(key)
		super(S3MediaStoreTest, self).tearDown()

	def test_store_media(self):
		self.mediastore.store_media(self.binary, self.path)
		assert_equal(self.mediastore.get_media(self.path), self.binary)
		self.mediastore.remove_media(self.path)
