import database.schema

from sqlalchemy import and_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict


class BuildConsolesReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(BuildConsolesReadHandler, self).__init__("build_consoles", "read")

	def get_build_console_from_id(self, user_id, build_console_id):
		build_console = database.schema.build_console

		query = build_console.select().where(
			build_console.c.id == build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			return to_dict(row, build_console.columns)
		else:
			raise NoSuchBuildConsoleError(build_console_id)

	def get_build_consoles(self, user_id, change_id):
		build = database.schema.build
		build_console = database.schema.build_console

		query = build_console.join(build).select(use_labels=True).where(
			build.c.change_id == change_id
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return [to_dict(row, build_console.columns, tablename=build_console.name) for row in sqlconn.execute(query)]

	def get_output_lines(self, user_id, build_console_id):
		console_output = database.schema.console_output
		build_console = database.schema.build_console

		output_query = console_output.select().where(console_output.c.build_console_id == build_console_id)
		metadata_query = build_console.select().where(build_console.c.id == build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return {row[console_output.c.line_number]: row[console_output.c.line] for row in sqlconn.execute(output_query)}

	def get_console_output(self, user_id, build_console_id):
		console_output = database.schema.console_output
		build_console = database.schema.build_console

		output_query = console_output.select().where(console_output.c.build_console_id == build_console_id)
		metadata_query = build_console.select().where(build_console.c.id == build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			output = dict([(row[console_output.c.line_number], row[console_output.c.line]) for row in sqlconn.execute(output_query)])
			console_metadata = to_dict(sqlconn.execute(metadata_query).first(), build_console.columns)
			console_metadata[console_output.name] = output
			return console_metadata

	def can_hear_build_console_events(self, user_id, id_to_listen_to):
		return True


class NoSuchBuildConsoleError(Exception):
	pass
