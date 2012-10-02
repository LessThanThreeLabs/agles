from redis import Redis
from sqlalchemy import create_engine

from settings import database


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