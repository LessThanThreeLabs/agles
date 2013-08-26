from sqlalchemy import Table, Column, Boolean, Integer, String, Text, Sequence, MetaData, ForeignKey, UniqueConstraint, CheckConstraint
from sqlalchemy import event, text, DDL
from sqlalchemy import select, func
from sqlalchemy.exc import SQLAlchemyError
from database.engine import ConnectionFactory


metadata = MetaData()

# We reserve the first 999 users as special users
user = Table('user', metadata,
	Column('id', Integer, Sequence('user_id_seq', start=1000), primary_key=True),
	Column('email', String, nullable=False),
	Column('first_name', String, nullable=False),
	Column('last_name', String, nullable=False),
	Column('password_hash', String(88), nullable=False),
	Column('salt', String(24), nullable=False),
	Column('github_oauth', String, nullable=True),
	Column('admin', Boolean, nullable=False, default=False),
	Column('created', Integer, nullable=False),
	Column('deleted', Integer, nullable=False, default=0),  # when deleted, set this column to the id

	UniqueConstraint('email', 'deleted'),
	CheckConstraint('deleted = 0 OR id = deleted')
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
	Column('uri', String, nullable=False),  # this is the clone uri
	Column('repostore_id', Integer, ForeignKey('repostore.id'), nullable=False),
	Column('forward_url', String, nullable=False),  # required forwarding url for repositories
	Column('created', Integer, nullable=False),
	Column('deleted', Integer, nullable=False, default=0),  # when deleted, set this column to the id
	Column('type', String, nullable=False),	 # the type (git, hg ...) of the repository

	UniqueConstraint('uri', 'deleted'),
	CheckConstraint('deleted = 0 OR id = deleted')
)

commit = Table('commit', metadata,
	Column('id', Integer, primary_key=True),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('sha', String, nullable=False),
	Column('base_sha', String, nullable=True),
	Column('message', String, nullable=False),
	Column('timestamp', Integer, nullable=False)
)

change = Table('change', metadata,
	Column('id', Integer, primary_key=True),
	Column('commit_id', Integer, ForeignKey('commit.id'), nullable=False),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('merge_target', String, nullable=False),
	Column('number', Integer, nullable=False),
	Column('verification_status', String, nullable=False),
	Column('merge_status', String, nullable=True),
	Column('create_time', Integer, nullable=False),
	Column('start_time', Integer, nullable=True),
	Column('end_time', Integer, nullable=True),

	UniqueConstraint('repo_id', 'number')
)

build = Table('build', metadata,
	Column('id', Integer, primary_key=True),
	Column('commit_id', Integer, ForeignKey('commit.id'), nullable=False),
	Column('change_id', Integer, ForeignKey('change.id'), nullable=False),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('status', String, nullable=False),
	Column('create_time', Integer, nullable=False),
	Column('start_time', Integer, nullable=True),
	Column('end_time', Integer, nullable=True)
)

virtual_machine = Table('virtual_machine', metadata,
	Column('id', Integer, primary_key=True),
	Column('type', String, nullable=False),
	Column('instance_id', String, nullable=False),
	Column('pool_slot', Integer, nullable=False),
	Column('username', String, nullable=False)
)

build_console = Table('build_console', metadata,
	Column('id', Integer, primary_key=True),
	Column('build_id', Integer, ForeignKey('build.id'), nullable=False),
	Column('repo_id', Integer, ForeignKey('repo.id'), nullable=False),
	Column('type', String, nullable=False),
	Column('subtype', String, nullable=False),
	Column('subtype_priority', Integer, nullable=False),
	Column('start_time', Integer, nullable=False),
	Column('end_time', Integer, nullable=True),
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

change_export_uri = Table('change_export_uri', metadata,
	Column('id', Integer, primary_key=True),
	Column('change_id', Integer, ForeignKey('change.id'), nullable=False),
	Column('uri', String, nullable=False),

	UniqueConstraint('change_id', 'uri')
)

patch = Table('patch', metadata,
	Column('id', Integer, primary_key=True),
	Column('change_id', Integer, ForeignKey('change.id'), nullable=False),
	Column('contents', Text)
)

repostore = Table('repostore', metadata,
	Column('id', Integer, primary_key=True),
	Column('ip_address', String, nullable=False),
	Column('repositories_path', String, nullable=False),

	UniqueConstraint('ip_address', 'repositories_path')
)

ssh_pubkey = Table('ssh_pubkey', metadata,
	Column('id', Integer, primary_key=True),
	Column('user_id', Integer, ForeignKey('user.id'), nullable=False),
	Column('alias', String, nullable=False),
	Column('ssh_key', String, nullable=False, unique=True),
	Column('timestamp', Integer, nullable=True),

	UniqueConstraint('user_id', 'alias')
)

system_setting = Table('system_setting', metadata,
	Column('id', Integer, primary_key=True),
	Column('resource', String, nullable=False),
	Column('key', String, nullable=False),
	Column('value', String, nullable=False),

	UniqueConstraint('resource', 'key')
)

temp_string = Table('temp', metadata,
	Column('id', Integer, primary_key=True),
	Column('string', String, nullable=False)
)


def _create_and_initialize(engine):
	metadata.create_all(engine)
	insert_admin_user()
	insert_admin_api_user()
	insert_admin_verifier()


def insert_admin_user():
	query = select([func.count(user.c.id)]).where(user.c.id == 1)
	ins = user.insert().values(id=1, email="admin-koala@koalitycode.com", first_name="Koality", last_name="Admin",
		password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
		salt="GMZhGiZU4/JYE3NlmCZgGA==", created=0, admin=True)
	with ConnectionFactory.get_sql_connection() as sqlconn:
		row = sqlconn.execute(query).first()
		if row[0] == 0:
			sqlconn.execute(ins)


def insert_admin_api_user():
	query = select([func.count(user.c.id)]).where(user.c.id == 2)
	ins = user.insert().values(id=2, email="api-koala@koalitycode.com", first_name="Koality", last_name="Api",
		password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
		salt="GMZhGiZU4/JYE3NlmCZgGA==", created=0, admin=True)
	with ConnectionFactory.get_sql_connection() as sqlconn:
		row = sqlconn.execute(query).first()
		if row[0] == 0:
			sqlconn.execute(ins)


def insert_admin_verifier():
	query = select([func.count(user.c.id)]).where(user.c.id == 3)
	ins = user.insert().values(id=3, email="verify-koala@koalitycode.com", first_name="Koality", last_name="Verifier",
		password_hash="mooonIJXsb0zgz2V0LXvN/N4N4zbZE9FadrFl/YBJvzh3Z8O3VT/FH1q6OzWplbrX99D++PO6mpez7QdoIUQ6A==",
		salt="GMZhGiZU4/JYE3NlmCZgGA==", created=0, admin=True)
	with ConnectionFactory.get_sql_connection() as sqlconn:
		row = sqlconn.execute(query).first()
		if row[0] == 0:
			sqlconn.execute(ins)


def reseed_db():
	# TODO: uncomment and fix this
	#import util.log
	#util.log.configure()
	#logging.getLogger("Schema").critical("Database reseeded")

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
