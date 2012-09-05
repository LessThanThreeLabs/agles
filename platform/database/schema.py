from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey

from database.engine import EngineFactory


metadata = MetaData()

users = Table('user', metadata,
    Column('id', Integer, primary_key=True),
    Column('username', String, nullable=False),
    Column('name', String, nullable=False)
)

repositories = Table('repository', metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String, nullable=False),
    Column('hash', String, nullable=False),
    Column('machine_id', Integer, ForeignKey('machine.id'), nullable=False)
)

machine = Table('machine', metadata,
    Column('id', Integer, primary_key=True),
    Column('uri', String, nullable=False)
)

ssh_pubkeys = Table('ssh_pubkey', metadata,
    Column('id', Integer, primary_key=True),
    Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
    Column('ssh_key', String, nullable=False)
)


def main():
    engine = EngineFactory.get_engine()
    metadata.create_all(engine)

if __name__ == "__main__":
    main()
