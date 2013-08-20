import collections
import time

from sqlalchemy import and_, or_
from sqlalchemy import bindparam
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

from database import schema
from database.engine import ConnectionFactory
from model_server.build_consoles import ConsoleType
from model_server.rpc_handler import ModelServerRpcHandler


class BuildConsolesUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildConsolesUpdateHandler, self).__init__("build_consoles", "update")

	def add_subtype(self, build_id, type, subtype, priority=None):
		assert type in ConsoleType.valid_types

		build_console = schema.build_console
		build = schema.build

		query = select([func.max(build_console.c.subtype_priority)],
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type
			),
			[build_console]
		)

		if priority is None:
			with ConnectionFactory.get_sql_connection() as sqlconn:
				max_priority_result = sqlconn.execute(query).first()
			if max_priority_result and max_priority_result[0] is not None:
				priority = max_priority_result[0] + 1
			else:
				priority = 0

		build_query = build.select().where(build.c.id == build_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			build_row = sqlconn.execute(build_query).first()
			assert build_row is not None
			repo_id = build_row[build.c.repo_id]
			change_id = build_row[build.c.change_id]  # TODO: This is a hack for the front end

		start_time = time.time()

		with ConnectionFactory.get_sql_connection() as sqlconn:
			ins = build_console.insert().values(
				build_id=build_id,
				repo_id=repo_id,
				type=type,
				subtype=subtype,
				subtype_priority=priority,
				start_time=start_time
			)
			console_id = sqlconn.execute(ins).inserted_primary_key[0]
			# TODO: This is firing to changes as a hack for the front end. Needs to go back to builds in the future
			self.publish_event("changes", change_id, "new build console", id=console_id, type=type, subtype=subtype,
				subtype_priority=priority, start_time=start_time, return_code=None)

	def append_console_lines(self, build_id, read_lines, type, subtype):
		"""
		:param build_id: The build id this console is relevant to.
		:param read_lines: A map from line numbers to lines
		:param type: The console type we are appending to.
		:param subtype: The console subtype we are appending to.
		"""
		build_console = schema.build_console
		console_output = schema.console_output

		build_console_query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type,
				build_console.c.subtype == subtype,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(build_console_query).first()
			assert row is not None

			build_console_id = row[build_console.c.id]
			existing_lines_query = console_output.select().where(
				and_(console_output.c.build_console_id == build_console_id,
					or_(*(console_output.c.line_number == line_number for line_number in read_lines.iterkeys()))
				)
			)
			existing_lines = [row[console_output.c.line_number] for row in sqlconn.execute(existing_lines_query)]
			if existing_lines:
				sqlconn.execute(
					console_output.update().where(
						and_(
							console_output.c.build_console_id == build_console_id,
							console_output.c.line_number == bindparam('b_line_number')
						)
					).values(line=bindparam('b_line')),
					[{'b_line_number': line_number, 'b_line': read_lines[line_number]} for line_number in existing_lines]
				)
			new_lines = read_lines
			for line_number in existing_lines:
				del new_lines[line_number]
			if new_lines:
				sqlconn.execute(
					console_output.insert().values(
						build_console_id=build_console_id,
						line_number=bindparam('b_line_number'),
						line=bindparam('b_line')
					),
					[{'b_line_number': line_number, 'b_line': line} for line_number, line in read_lines.items()]
				)
			self.publish_event("build_consoles", build_console_id, "new output",
				**{str(line_number): line for line_number, line in read_lines.items()})

	def _get_build_console_id(self, sqlconn, build_id, type, subtype):
		build_console = schema.build_console
		console_output = schema.console_output

		query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type,
				build_console.c.subtype == subtype,
			)
		)

		row = sqlconn.execute(query).first()
		return row[build_console.c.id] if row else None

	def store_xunit_contents(self, build_id, type, subtype, xunit_contents):
		xunit = database.schema.xunit

		with ConnectionFactory.get_sql_connection() as sqlconn:
			build_console_id = self._get_build_console_id(sqlconn, build_id, type, subtype)
			insert_list = [{'build_console_id': build_console_id, 'path': k, 'contents': v} for k, v in xunit_contents.iteritems()]
			sqlconn.execute(xunit.insert(), *insert_list)

		self.publish_event("build_consoles", build_console_id, "xunit stored")

	def set_return_code(self, build_id, return_code, type, subtype):
		build_console = schema.build_console
		build = schema.build

		end_time = time.time()

		query = build_console.select().where(
			and_(
				build_console.c.build_id == build_id,
				build_console.c.type == type,
				build_console.c.subtype == subtype,
			)
		)
		change_id_query = build.select().where(build.c.id == build_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None

			build_console_id = row[build_console.c.id]
			sqlconn.execute(
				build_console.update().where(
					build_console.c.id == build_console_id
				).values(
					return_code=return_code,
					end_time=end_time
				)
			)

			change_id = sqlconn.execute(change_id_query).first()[build.c.change_id]

		self.publish_event("changes", change_id, "return code added",
			build_console_id=build_console_id, return_code=return_code, end_time=end_time)
