import collections

from sqlalchemy import and_
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class BuildConsolesUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildConsolesUpdateHandler, self).__init__("build_consoles", "update")

	def add_subtypes(self, build_id, type, ordered_subtypes):
		assert isinstance(ordered_subtypes, collections.Iterable)
		assert type in ['setup', 'compile', 'test']

		build_console = schema.build_console
		build = schema.build

		query = select([func.max(build_console.c.subtype_priority)],
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type
			),
			[build_console]
		)

		build_query = build.select().where(build.c.id == build_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			max_priority_result = sqlconn.execute(query).first()
			build_row = sqlconn.execute(build_query).first()
			assert build_row is not None
			repo_id = build_row[build.c.repo_id]
			change_id = build_row[build.c.change_id]  # TODO: This is a hack for the front end

		if max_priority_result and max_priority_result[0]:
			starting_priority = max_priority_result[0] + 1
		else:
			starting_priority = 0

		for index, subtype in enumerate(ordered_subtypes):
			with ConnectionFactory.get_sql_connection() as sqlconn:
				priority = index + starting_priority
				ins = build_console.insert().values(
					build_id=build_id,
					repo_id=repo_id,
					type=type,
					subtype=subtype,
					subtype_priority=priority,
				)
				console_id = sqlconn.execute(ins).inserted_primary_key[0]
				# TODO: This is firing to changes as a hack for the front end. Needs to go back to builds in the future
				self.publish_event("changes", change_id, "new build console", id=console_id, type=type, subtype=subtype, return_code=None)

	def append_console_lines(self, build_id, read_lines, type, subtype):
		"""
		:param build_id: The build id this console is relevant to.
		:param read_lines: A map from line numbers to lines
		:param type: The console type we are appending to.
		:param subtype: The console subtype we are appending to.
		"""
		build_console = schema.build_console
		console_output = schema.console_output

		query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type,
				build_console.c.subtype == subtype,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None

			build_console_id = row[build_console.c.id]
			for line_number, line in sorted(read_lines.items()):
				try:
					sqlconn.execute(
						console_output.insert().values(
							build_console_id=build_console_id,
							line_number=line_number,
							line=line
						)
					)
				except IntegrityError:
					sqlconn.execute(
						console_output.update().where(
							and_(
								console_output.c.build_console_id == build_console_id,
								console_output.c.line_number == line_number
							)
						).values(line=line)
					)
			self.publish_event("build_consoles", build_console_id, "new output",
				**{str(line_number): line for line_number, line in read_lines.items()})

	def set_return_code(self, build_id, return_code, type, subtype):
		build_console = schema.build_console

		query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type,
				build_console.c.subtype == subtype,
			)
		)
		change_id_query = build.select().where(build_id == build_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None

			build_console_id = row[build_console.c.id]
			sqlconn.execute(
				build_console.update().where(
					build_console.c.id == build_console_id
				).values(return_code=return_code)
			)

			change_id = sqlconn.execute(change_id_query).first()[build.c.change_id]

		self.publish_event("changes", change_id, "return code added",
			build_console_id=build_console_id, return_code=return_code)
