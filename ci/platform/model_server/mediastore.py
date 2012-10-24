from boto.s3.key import Key

from database.engine import ConnectionFactory

class MediaStore(object):
	def store_media(self, media_binary, path):
		raise NotImplementedError("Child classes should implement this!")

class S3MediaStore(MediaStore):
	def __init__(self, bucket_name):
		self.bucket_name = bucket_name

	def store_media(self, media_binary, path):
		s3key = Key(ConnectionFactory.get_s3_bucket(self.bucket_name))
		s3key.key = path
		s3key.set_contents_from_string(media_binary)

	def get_media(self, path):
		bucket = ConnectionFactory.get_s3_bucket(self.bucket_name)
		s3key = bucket.get_key(path)
		return s3key.get_contents_as_string()

	def remove_media(self, path):
		bucket = ConnectionFactory.get_s3_bucket(self.bucket_name)
		bucket.delete_key(path)