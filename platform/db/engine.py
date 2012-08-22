from sqlalchemy import create_engine
from settings import db


class EngineFactory(object):
    _ENGINE = create_engine(db.db_url)

    @classmethod
    def get_engine(cls):
        return cls._ENGINE
