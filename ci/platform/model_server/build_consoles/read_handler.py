import database.schema

from sqlalchemy import and_, func, select

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict


class BuildConsolesReadHandler(ModelServerRpcHandler):
	def __init__(self, channel=None):
		super(BuildConsolesReadHandler, self).__init__("build_consoles", "read", channel)

	def get_build_console_from_id(self, user_id, build_console_id):
		build_console = database.schema.build_console

		query = build_console.select().where(
			build_console.c.id == build_console_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			console = to_dict(row, build_console.columns)
			console['output_types'] = self.get_valid_output_types(user_id, build_console_id)
			return console
		else:
			raise NoSuchBuildConsoleError(build_console_id)

	def get_build_consoles(self, user_id, change_id):
		build = database.schema.build
		build_console = database.schema.build_console

		query = build_console.join(build).select(use_labels=True).where(
			build.c.change_id == change_id
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			build_consoles = [to_dict(row, build_console.columns, tablename=build_console.name) for row in sqlconn.execute(query)]

		for console in build_consoles:
			console['output_types'] = self.get_valid_output_types(user_id, console[build_console.c.id.name])

		return build_consoles

	def get_output_lines(self, user_id, build_console_id, offset=0, num_results=1000):
		console_output = database.schema.console_output
		build_console = database.schema.build_console

		with ConnectionFactory.get_sql_connection() as sqlconn:
			max_line_query = select([func.max(console_output.c.line_number)]).where(console_output.c.build_console_id == build_console_id)
			max_line_row = sqlconn.execute(max_line_query).first()
			if max_line_row and max_line_row[0] is not None:
				max_line = max_line_row[0]
				output_query = console_output.select().where(
					console_output.c.build_console_id == build_console_id
				).order_by(
					console_output.c.line_number.desc(),
					console_output.c.id.asc()
				).where(
					and_(
						console_output.c.line_number > max_line - offset - num_results,
						console_output.c.line_number <= max_line - offset
					)
				)
				return {row[console_output.c.line_number]: row[console_output.c.line] for row in sqlconn.execute(output_query)}
			else:
				return {}

	def get_build_console_id(self, user_id, build_id, type, subtype):
		build_console = database.schema.build_console

		query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type,
				build_console.c.subtype == subtype
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[build_console.c.id] if row else None

	def get_xunit_from_id(self, user_id, build_console_id):
		build_console = database.schema.build_console
		xunit = database.schema.xunit

		query = xunit.select().where(xunit.c.build_console_id == build_console_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)

		return [to_dict(row, xunit.columns) for row in rows]

	# TODO: We should find a smarter way to do this whenever there are a lot of different output types
	def get_valid_output_types(self, user_id, build_console_id):
		if self.get_xunit_from_id(user_id, build_console_id):
			return ['console', 'xunit']
		return ['console']

	def can_hear_build_console_events(self, user_id, id_to_listen_to):
		return True


class NoSuchBuildConsoleError(Exception):
	pass
