from sqlalchemy import create_engine
from settings import database


class EngineFactory(object):
    _ENGINE = create_engine(database.database_url)

    @classmethod
    def get_engine(cls):
        return cls._ENGINE

    @classmethod
    def get_connection(cls):
        return cls.get_engine().connect()
