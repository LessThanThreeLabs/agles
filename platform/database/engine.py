from boto.s3.connection import S3Connection
from redis import Redis
from sqlalchemy import create_engine

from settings import database
from settings.aws import access_key_id, secret_access_key


class ConnectionFactory(object):
	_ENGINE = create_engine(database.sql_database_url)

	@classmethod
	def get_sql_engine(cls):
		return cls._ENGINE

	@classmethod
	def get_sql_connection(cls):
		return cls.get_sql_engine().connect()

	@classmethod
	def get_redis_connection(cls):
		return Redis(**database.redis_connection_params)

	@classmethod
	def get_s3_bucket(cls, bucket_name):
		s3conn = S3Connection(access_key_id, secret_access_key)
		return s3conn.get_bucket(bucket_name)

