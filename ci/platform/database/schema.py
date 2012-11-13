import contextlib

from sqlalchemy import Table, Column, Boolean, Integer, SmallInteger, String, Text, LargeBinary, MetaData, ForeignKey, UniqueConstraint

from database.engine import ConnectionFactory


metadata = MetaData()

user = Table('user', metadata,
	Column('id', Integer, primary_key=True),
	Column('email', String, nullable=False, unique=True),
	Column('name', String, nullable=False),
	Column('password_hash', LargeBinary(64), nullable=False),
	Column('salt', String(16), nullable=False)
)

media = Table('media', metadata,
	Column('id', Integer, primary_key=True),
	Column('hash', String(32), nullable=False)
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
	Column('machine_id', Integer, ForeignKey('machine.id'), nullable=False),
	Column('default_permissions', SmallInteger, nullable=False)  # This is a bitmask
)

# refer to util.permissions for permission bitmask documentation
permission = Table('permission', metadata,
	Column('id', Integer, primary_key=True),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('repo_hash', String, ForeignKey('repo.hash'), nullable=False, index=True),
	Column('permissions', SmallInteger, nullable=False),  # This is a bitmask

	UniqueConstraint('user_id', 'repo_hash')
)

commit = Table('commit', metadata,
	Column('id', Integer, primary_key=True),
	Column('repo_hash', String, ForeignKey('repo.hash'), nullable=False),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('message', String, nullable=False),
	Column('timestamp', Integer, nullable=False)
)

change = Table('change', metadata,
	Column('id', Integer, primary_key=True),
	Column('commit_id', Integer, ForeignKey('commit.id'), nullable=False),
	Column('merge_target', String, nullable=False),
	Column('number', Integer, nullable=False),
	Column('status', String, nullable=False),
	Column('start_time', Integer, nullable=True),
	Column('end_time', Integer, nullable=True)
)

build = Table('build', metadata,
	Column('id', Integer, primary_key=True),
	Column('change_id', Integer, ForeignKey('change.id'), nullable=False),
	Column('is_primary', Boolean, nullable=False),
	Column('status', String, nullable=False),
	Column('start_time', Integer, nullable=True),
	Column('end_time', Integer, nullable=True)
)

"""Maps builds to lists of commits"""
build_commits_map = Table('build_commits_map', metadata,
	Column('build_id', Integer, ForeignKey('build.id'), nullable=False),
	Column('commit_id', Integer, ForeignKey('commit.id'), nullable=False)
)

build_console = Table('build_console', metadata,
	Column('id', Integer, primary_key=True),
	Column('build_id', Integer, ForeignKey('build.id'), nullable=False),
	Column('type', String, nullable=False),
	Column('subcategory', String, nullable=False),
	Column('console_output', Text, nullable=False),

	UniqueConstraint('build_id', 'type')
)

machine = Table('machine', metadata,
	Column('id', Integer, primary_key=True),
	Column('uri', String, nullable=False, unique=True)
)

ssh_pubkeys = Table('ssh_pubkey', metadata,
	Column('id', Integer, primary_key=True),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('alias', String, nullable=False),
	Column('ssh_key', String, nullable=False, unique=True)
)


def reseed_db():
	engine = ConnectionFactory.get_sql_engine()
	with contextlib.closing(engine.connect()):
		for table in reversed(metadata.sorted_tables):
			table.drop(engine, checkfirst=True)
	metadata.create_all(engine)


def main():
	print "Creating database schema..."
	engine = ConnectionFactory.get_sql_engine()
	metadata.create_all(engine)

if __name__ == "__main__":
	main()
