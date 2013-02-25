import pipes

from setup_tools import InvalidConfigurationException, SetupCommand


class DatabaseParser(object):
	def __init__(self, database_type):
		self.database_type = database_type

	def parse_databases(self, databases):
		database_steps = []
		for database in databases:
			database_steps = database_steps + self.parse_database(database)
		return database_steps

	def parse_database(self, database):
		if isinstance(database, dict):
			if not (len(database.items()) and 'name' in database and 'username' in database):
				raise InvalidConfigurationException("Could not parse %s database: %s" % (self.database_type, database))
			create_database_command = self.create_database_command(database['name'])
			create_user_command = self.create_user_command(database['username'], database['name'])
		else:
			raise InvalidConfigurationException("Could not parse %s database: %s" % (self.database_type, database))
		return [create_database_command, create_user_command]

	def create_database_command(self, name):
		raise NotImplementedError()

	def create_user_command(self, username):
		raise NotImplementedError()


class OmnibusDatabaseParser(object):
	def __init__(self):
		self.database_dispatcher = {
			'postgres': PostgresDatabaseParser(),
			'mysql': MysqlDatabaseParser()
		}

	def parse_databases(self, database_type, databases):
		try:
			parser = self.database_dispatcher[database_type]
		except KeyError:
			raise InvalidConfigurationException("Unsupported database type: %s" % database_type)
		return parser.parse_databases(databases)


class PostgresDatabaseParser(DatabaseParser):
	def __init__(self):
		super(PostgresDatabaseParser, self).__init__('postgres')

	def create_database_command(self, name):
		return self.postgres_command(";\n".join((
			"drop database if exists %s" % name,
			"create database %s" % name)))

	def create_user_command(self, username, database_name):
		return self.postgres_command(";\n".join((
			"drop user if exists %s" % username,
			"create user %s with password ''" % username,
			"grant all privileges on database %s to %s" % (database_name, username))))

	def postgres_command(self, command):
		return SetupCommand("psql -U postgres -c %s" % pipes.quote(command))


class MysqlDatabaseParser(DatabaseParser):
	def __init__(self):
		super(MysqlDatabaseParser, self).__init__('mysql')

	def create_database_command(self, name):
		return self.mysql_command(";\n".join((
			"drop database if exists %s" % name,
			"create database %s" % name)))

	def create_user_command(self, username, database_name):
		return self.mysql_command("grant all privileges on %s.* to '%s'@localhost" % (database_name, username))

	def mysql_command(self, command):
		return SetupCommand("mysql -u root -e %s" % pipes.quote(command))
