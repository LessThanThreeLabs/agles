from sqlalchemy import Table, Column, Integer, String, DateTime, MetaData, ForeignKey, UniqueConstraint

from database.engine import EngineFactory


metadata = MetaData()

user = Table('user', metadata,
	Column('id', Integer, primary_key=True),
	Column('username', String, nullable=False),
	Column('name', String, nullable=False)
)

uri_repo_map = Table('uri_repo_map', metadata,
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

commit = Table('commit', metadata,
	Column('id', Integer, primary_key=True),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('timestamp', DateTime, nullable=False)
)

build = Table('build', metadata,
	Column('id', Integer, primary_key=True),
	Column('commit_id', Integer, ForeignKey('commit.id'), nullable=False),
	Column('number', Integer, nullable=False),
	Column('status', String, nullable=False),
	Column('start_time', DateTime, nullable=False),
	Column('end_time', DateTime, nullable=False)
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


def reseed_db():
	engine = EngineFactory.get_engine()
	metadata.drop_all(engine)
	metadata.create_all(engine)


def main():
	print "Creating database schema..."
	engine = EngineFactory.get_engine()
	metadata.create_all(engine)

if __name__ == "__main__":
	main()
