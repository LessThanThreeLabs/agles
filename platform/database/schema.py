from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey, UniqueConstraint

from database.engine import EngineFactory


metadata = MetaData()

user = Table('user', metadata,
	Column('id', Integer, primary_key=True),
	Column('username', String, nullable=False),
	Column('name', String, nullable=False)
)

uri_repository_map = Table('uri_repo_map', metadata,
	Column('id', Integer, primary_key=True),
	Column('uri', String, nullable=False, unique=True),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	
	UniqueConstraint('uri', 'repo_id')
)

repo = Table('repo', metadata,
	Column('id', Integer, primary_key=True),
	Column('name', String, nullable=False),
	Column('hash', String, nullable=False, index=True, unique=True),
	Column('machine_id', Integer, ForeignKey('machine.id'), nullable=False)
)

machine = Table('machine', metadata,
	Column('id', Integer, primary_key=True),
	Column('uri', String, nullable=False, unique=True)
)

ssh_pubkeys = Table('ssh_pubkey', metadata,
	Column('id', Integer, primary_key=True),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('ssh_key', String, nullable=False, unique=True)
)


def main():
	print "Creating database schema..."
	engine = EngineFactory.get_engine()
	metadata.create_all(engine)

if __name__ == "__main__":
	main()
