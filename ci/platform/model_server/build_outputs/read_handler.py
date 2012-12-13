import database.schema

from collections import defaultdict

from sqlalchemy import and_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import RepositoryPermissions, InvalidPermissionsError
from util.sql import to_dict


class BuildOutputsReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildOutputsReadHandler, self).__init__("build_outputs", "read")

	def _subtypes_query(self, build_id, console):
		build_console = database.schema.build_console

		query = build_console.select().where(
			and_(
				build_console.c.build_id==build_id,
				build_console.c.type==console,
			)
		)
		return query

	def _has_permission(self, user_id, build_id):
		build = database.schema.build
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo
		permission = database.schema.permission

		query = build.join(change).join(commit).join(repo).join(permission).select().where(
			and_(
				build.c.id==build_id,
				permission.c.user_id==user_id,
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			if not row:
				return False
			else:
				return RepositoryPermissions.has_permissions(
					row[permission.c.permissions], RepositoryPermissions.R)

	def get_build_console_ids(self, user_id, build_id):
		if not self._has_permission(user_id, build_id):
			raise InvalidPermissionsError("user_id: %d, build_id: %d" % (user_id, build_id))

		build_console = database.schema.build_console

		query = build_console.select().where(
			build_console.c.build_id==build_id
		)

		result = defaultdict(list)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			for row in sqlconn.execute(query):
				type = row[build_console.c.type]
				row_id = row[build_console.c.id]
				subtype_priority = row[build_console.c.subtype_priority]
				result[type].append((subtype_priority, row_id))

		for k, v in result.iteritems():
			sorted_v = sorted(v, key=lambda tup: tup[0])
			result[k] = [row_id for priority, row_id in sorted_v]
		return result

	def _has_build_console_permission(self, user_id, build_console_id):
		build = database.schema.build
		build_console = database.schema.build_console
		change = database.schema.change
		commit = database.schema.commit
		repo = database.schema.repo
		permission = database.schema.permission

		query = build_console.join(build).join(change).join(commit).join(repo).join(permission).select().where(
			and_(
				build_console.c.id==build_console_id,
				permission.c.user_id==user_id,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			if not row:
				return False
			else:
				return RepositoryPermissions.has_permissions(
					row[permission.c.permissions], RepositoryPermissions.R)

	def get_console_output(self, user_id, build_console_id):
		if not self._has_build_console_permission(user_id, build_console_id):
			raise InvalidPermissionsError("user_id: %d, build_console_id: %d" %
										  (user_id, build_console_id))

		console_output = database.schema.console_output
		build_console = database.schema.build_console

		output_query = console_output.select().where(console_output.c.build_console_id==build_console_id)
		metadata_query = build_console.select().where(build_console.c.id==build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			output = dict([(row[console_output.c.line_number], row[console_output.c.line]) for row in sqlconn.execute(output_query)])
			console_metadata = to_dict(sqlconn.execute(metadata_query).first(), build_console.columns)
			console_metadata[console_output.name] = output
			return console_metadata
