from boto.s3.connection import S3Connection
from redis import StrictRedis
from sqlalchemy import create_engine

from settings.aws import access_key_id, secret_access_key
from settings.database import DatabaseSettings


class ConnectionFactory(object):
	_ENGINE = create_engine(DatabaseSettings.sql_database_url)

	@classmethod
	def recreate_engine(cls):
		cls._ENGINE = create_engine(DatabaseSettings.sql_database_url)

	@classmethod
	def get_sql_engine(cls):
		return cls._ENGINE

	@classmethod
	def get_sql_connection(cls):
		return cls.get_sql_engine().connect()

	@classmethod
	def get_redis_connection(cls):
		return StrictRedis(**DatabaseSettings.redis_connection_params)

	@classmethod
	def get_s3_bucket(cls, bucket_name):
		s3conn = S3Connection(access_key_id, secret_access_key)
		return s3conn.get_bucket(bucket_name)
