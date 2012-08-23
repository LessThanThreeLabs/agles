from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey

from db.engine import EngineFactory


metadata = MetaData()

users = Table('user', metadata,
	Column(id, Integer, primary_key=True),
)

ssh_pubkeys = Table('ssh_pubkeys', metadata,
	Column('id', Integer, primary_key=True),
	Column('user_id', Integer, ForeignKey('users.id'), nullable=False),
	Column('ssh_key', String, nullable=False)
)


def main():
	engine = EngineFactory.get_engine()
	metadata.create_all(engine)

if __name__ == "__main__":
	main()
