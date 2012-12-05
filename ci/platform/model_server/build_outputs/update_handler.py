import collections

from sqlalchemy import and_
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from model_server.build_outputs import REDIS_SUBTYPE_KEY, REDIS_TYPE_KEY


class BuildOutputsUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildOutputsUpdateHandler, self).__init__("build_outputs", "update")

	def add_subtypes(self, build_id, type, ordered_subtypes):
		assert isinstance(ordered_subtypes, collections.Iterable)

		build_console = schema.build_console

		query = select([func.max(build_console.c.subtype_priority)],
			and_(
				build_console.c.build_id==build_id,
				build_console.c.type==type
			),
			[build_console]
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			max_priority_result = sqlconn.execute(query).first()
		if max_priority_result and max_priority_result[0]:
			starting_priority = max_priority_result[0] + 1
		else:
			starting_priority = 0

		console_map = {}
		for index, subtype in enumerate(ordered_subtypes):
			with ConnectionFactory.get_sql_connection() as sqlconn:
				priority = index + starting_priority
				ins = build_console.insert().values(
					build_id=build_id,
					type=type,
					subtype=subtype,
					subtype_priority=priority,
				)
				console_id = sqlconn.execute(ins).inserted_primary_key[0]
				console_map[subtype] = console_id
		self.publish_event("builds", build_id, "consoles added", type=type, console_map=console_map)

	def append_console_line(self, build_id, line_num, line, type, subtype):
		"""
		:param build_id: The build id this console is relevant to.
		:param line_num: The line number we're appending
		:param line: The line to append and store.
		:param type: The console type we are appending to.
		:param subtype: The console subtype we are appending to.
		"""
		build_console = schema.build_console
		console_output = schema.console_output

		query = build_console.select().where(
			and_(
				build_console.c.build_id==build_id,
				build_console.c.type==type,
				build_console.c.subtype==subtype,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None

			build_console_id = row[build_console.c.id]
			try:
				sqlconn.execute(
					console_output.insert().values(
						build_console_id=build_console_id,
						line_number=line_num,
						line=line
					)
				)
			except IntegrityError:
				sqlconn.execute(
					build_console.update().where(
						and_(
							console_output.c.build_console_id==build_console_id,
							console_output.c.line_number==line_num
						)
					).values(line=line)
				)
			self.publish_event("build_outputs", build_console_id, "line added",
				line_num=line_num, line=line)
