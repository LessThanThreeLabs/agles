import sqlalchemy.engine.url

from settings import Settings


class DatabaseSettings(Settings):
	def __init__(self):
		super(DatabaseSettings, self).__init__(
			postgres_host='localhost',
			redis_host='127.0.0.1',
			redis_port=6400,
			redis_db=0)
		self.add_values(
			sql_database_url=sqlalchemy.engine.url.URL("postgresql", host=self.postgres_host, database="koality"),
			redis_connection_params={"host": self.redis_host, "port": self.redis_port, "db": self.redis_db})

DatabaseSettings.initialize()
