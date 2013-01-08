import sqlalchemy.engine.url

sql_database_url = sqlalchemy.engine.url.URL("postgresql", host="localhost", database="koality")
redis_connection_params = {"host": "127.0.0.1", "port": 6400, "db": 0}
