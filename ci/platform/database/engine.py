from redis import StrictRedis
from sqlalchemy import create_engine

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
	def transaction_context(cls):
		return cls.get_sql_engine().begin()

	@classmethod
	def get_redis_connection(cls, redis_type):
		return StrictRedis(**DatabaseSettings.redis_connection_params[redis_type])
