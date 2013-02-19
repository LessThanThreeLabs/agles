from sqlalchemy import Table, Column, Boolean, Integer, String, Sequence, MetaData, ForeignKey, UniqueConstraint
from sqlalchemy import event, text, DDL
from sqlalchemy.exc import SQLAlchemyError
from database.engine import ConnectionFactory


metadata = MetaData()

# We reserve the first 999 users as special users
user = Table('user', metadata,
	Column('id', Integer, Sequence('user_id_seq', start=1000), primary_key=True),
	Column('email', String, nullable=False, unique=True),
	Column('first_name', String, nullable=False),
	Column('last_name', String, nullable=False),
	Column('password_hash', String(88), nullable=False),
	Column('salt', String(24), nullable=False),
	Column('admin', Boolean, nullable=False, default=False)
)

event.listen(
	user,
	"after_create",
	DDL("alter table %(table)s alter column id set default nextval('user_id_seq'::regclass);")
)

media = Table('media', metadata,
	Column('id', Integer, primary_key=True),
	Column('hash', String(32), nullable=False)
)

repo = Table('repo', metadata,
	Column('id', Integer, primary_key=True),
	Column('name', String, nullable=False),
	Column('uri', String, nullable=False, unique=True),  # this is the clone uri
	Column('repostore_id', Integer, ForeignKey('repostore.id'), nullable=False),
	Column('forward_url', String, nullable=False),  # required forwarding url for repositories
	Column('privatekey', String, nullable=False),  # rsa privkey
	Column('publickey', String, nullable=False),  # rsa pubkey
	Column('created', Integer, nullable=False)
)

commit = Table('commit', metadata,
	Column('id', Integer, primary_key=True),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('message', String, nullable=False),
	Column('timestamp', Integer, nullable=False)
)

change = Table('change', metadata,
	Column('id', Integer, primary_key=True),
	Column('commit_id', Integer, ForeignKey('commit.id'), nullable=False),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('merge_target', String, nullable=False),
	Column('number', Integer, nullable=False),
	Column('status', String, nullable=False),
	Column('start_time', Integer, nullable=True),
	Column('end_time', Integer, nullable=True)
)

build = Table('build', metadata,
	Column('id', Integer, primary_key=True),
	Column('change_id', Integer, ForeignKey('change.id'), nullable=False),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
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
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('type', String, nullable=False),
	Column('subtype', String, nullable=False),
	Column('subtype_priority', Integer, nullable=False),
	Column('return_code', Integer, nullable=True),

	UniqueConstraint('build_id', 'type', 'subtype')
)

console_output = Table('console_output', metadata,
	Column('id', Integer, primary_key=True),
	Column('build_console_id', Integer, ForeignKey('build_console.id'), nullable=False),
	Column('line_number', Integer, nullable=False),
	Column('line', String, nullable=False),

	UniqueConstraint('build_console_id', 'line_number')
)

repostore = Table('repostore', metadata,
	Column('id', Integer, primary_key=True),
	Column('host_name', String, nullable=False),
	Column('repositories_path', String, nullable=False),

	UniqueConstraint('host_name', 'repositories_path')
)

ssh_pubkey = Table('ssh_pubkey', metadata,
	Column('id', Integer, primary_key=True),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('alias', String, nullable=False),
	Column('ssh_key', String, nullable=False, unique=True),
	Column('timestamp', Integer, nullable=True),

	UniqueConstraint('user_id', 'alias')
)


def _create_and_initialize(engine):
	metadata.create_all(engine)
	_insert_admin_user()


def _insert_admin_user():
	ins = user.insert().values(id=1, email="lt3@getkoality.com", first_name="Admin", last_name="Admin",
		password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
		salt="GMZhGiZU4/JYE3NlmCZgGA==")
	with ConnectionFactory.get_sql_connection() as sqlconn:
		sqlconn.execute(ins)


def reseed_db():
	engine = ConnectionFactory.get_sql_engine()
	_drop_all_tables_and_sequences(engine)
	_create_and_initialize(engine)


def _get_table_list_from_db(engine):
	"""return a list of table names from the current
	databases public schema"""
	sql = "select table_name from information_schema.tables where table_schema='public'"
	execute = engine.execute
	return [name for (name, ) in execute(text(sql))]


def _get_seq_list_from_db(engine):
	"""return a list of the sequence names from the current
	databases public schema"""
	sql = "select sequence_name from information_schema.sequences where sequence_schema='public'"
	execute = engine.execute
	return [name for (name, ) in execute(text(sql))]


def _drop_all_tables_and_sequences(engine):
	execute = engine.execute
	for table in _get_table_list_from_db(engine):
		try:
			execute(text('DROP TABLE "%s" CASCADE' % table))
		except SQLAlchemyError as e:
			print e

	for seq in _get_seq_list_from_db(engine):
		try:
			execute(text('DROP SEQUENCE "%s" CASCADE' % seq))
		except SQLAlchemyError as e:
			print e


def main():
	print "Creating database schema..."
	engine = ConnectionFactory.get_sql_engine()
	_create_and_initialize(engine)

if __name__ == "__main__":
	main()
