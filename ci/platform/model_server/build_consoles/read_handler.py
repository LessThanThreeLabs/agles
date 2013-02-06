import database.schema

from sqlalchemy import and_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import RepositoryPermissions, InvalidPermissionsError
from util.sql import to_dict


class BuildConsolesReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildConsolesReadHandler, self).__init__("build_consoles", "read")

	def _subtypes_query(self, build_id, console):
		build_console = database.schema.build_console

		query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == console,
			)
		)
		return query

	def _has_permission(self, user_id, change_id):
		change = database.schema.change
		repo = database.schema.repo
		permission = database.schema.permission

		query = change.join(repo).join(permission).select().where(
			and_(
				change.c.id == change_id,
				permission.c.user_id == user_id,
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			if not row:
				return False
			else:
				return RepositoryPermissions.has_permissions(
					row[permission.c.permissions], RepositoryPermissions.R)

	def get_build_consoles(self, user_id, change_id):
		if not self._has_permission(user_id, change_id):
			raise InvalidPermissionsError("user_id: %d, change_id: %d" % (user_id, change_id))

		build = database.schema.build
		build_console = database.schema.build_console

		query = build_console.join(build).select().where(
			build.c.change_id == change_id
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [to_dict(row, build_console.columns, tablename=build_console.name) for row in sqlconn.execute(query)]

	def _has_build_console_permission(self, user_id, build_console_id):
		build_console = database.schema.build_console
		repo = database.schema.repo
		permission = database.schema.permission

		query = build_console.join(repo).join(permission).select().where(
			and_(
				build_console.c.id == build_console_id,
				permission.c.user_id == user_id,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			if not row:
				return False
			else:
				return RepositoryPermissions.has_permissions(
					row[permission.c.permissions], RepositoryPermissions.R)

	def get_output_lines(self, user_id, build_console_id):
		if not self._has_build_console_permission(user_id, build_console_id):
			raise InvalidPermissionsError("user_id: %d, build_console_id: %d" %
											(user_id, build_console_id))

		console_output = database.schema.console_output
		build_console = database.schema.build_console

		output_query = console_output.select().where(console_output.c.build_console_id == build_console_id)
		metadata_query = build_console.select().where(build_console.c.id == build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return {row[console_output.c.line_number]: row[console_output.c.line] for row in sqlconn.execute(output_query)}

	def get_console_output(self, user_id, build_console_id):
		if not self._has_build_console_permission(user_id, build_console_id):
			raise InvalidPermissionsError("user_id: %d, build_console_id: %d" %
											(user_id, build_console_id))

		console_output = database.schema.console_output
		build_console = database.schema.build_console

		output_query = console_output.select().where(console_output.c.build_console_id == build_console_id)
		metadata_query = build_console.select().where(build_console.c.id == build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			output = dict([(row[console_output.c.line_number], row[console_output.c.line]) for row in sqlconn.execute(output_query)])
			console_metadata = to_dict(sqlconn.execute(metadata_query).first(), build_console.columns)
			console_metadata[console_output.name] = output
			return console_metadata
