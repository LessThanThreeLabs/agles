import collections

from sqlalchemy import and_

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from model_server.build_outputs import REDIS_SUBTYPE_KEY, REDIS_TYPE_KEY


class BuildOutputsUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildOutputsUpdateHandler, self).__init__("build_outputs", "update")

	def init_subtypes(self, build_id, type, subtypes):
		assert isinstance(subtypes, collections.Iterable)

		trans = lambda subtype: REDIS_SUBTYPE_KEY % (build_id, type, subtype)
		subtype_keys = map(trans, subtypes)

		redis_conn = ConnectionFactory.get_redis_connection()
		redis_key = REDIS_TYPE_KEY % (build_id, type)
		[redis_conn.hset(redis_key, subtype_key, priority)
		for priority, subtype_key in enumerate(subtype_keys)]

	def append_console_line(self, build_id, line_num, line, type, subtype=""):
		""" The redis keys for build output are of the form build.output:build_id:type:subtype
		:param build_id: The build id this console is relevant to.
		:param line_num: The line number we're appending
		:param line: The line to append and store.
		:param type: The console type we are appending to.
		:param subtype: The console subtype we are appending to.
		"""
		build_console = schema.build_console
		query = build_console.select().where(
			and_(
				build_console.c.build_id==build_id,
				build_console.c.type==type,
				build_console.c.subtype==subtype,
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			if row:
				line = row[build_console.c.console_output] + "\n" + line
				update = build_console.update().where(build_console.c.id==row[build_console.c.id]).values(
					console_output=line
				)
				sqlconn.execute(update)
			else:
				ins = build_console.insert().values(
					build_id=build_id,
					type=type,
					subtype=subtype,
					console_output=line,
					subtype_priority=1,
				)
				sqlconn.execute(ins)


		#redis_key = REDIS_SUBTYPE_KEY % (build_id, type, subtype)
		#redis_conn = ConnectionFactory.get_redis_connection()
		#redis_conn.hset(redis_key, line_num, line)

	def _get_priority(self, redis_conn, build_id, type, subtype):
		type_key = REDIS_TYPE_KEY % (build_id, type)
		subtype_key = REDIS_SUBTYPE_KEY % (build_id, type, subtype)

		return int(redis_conn.hget(type_key, subtype_key))

	def _compact_output(self, redis_conn, build_id, type, subtype):
		redis_key = REDIS_SUBTYPE_KEY % (build_id, type, subtype)
		line_dict = redis_conn.hgetall(redis_key)
		_, lines = zip(*sorted(line_dict.iteritems(),
			key=lambda tup: int(tup[0]))) if line_dict else (None, [])
		complete_console_output = '\n'.join(lines)
		return complete_console_output

	def _remove_tmpdata(self, redis_conn, build_id, type, subtype):
		type_key = REDIS_TYPE_KEY % (build_id, type)
		subtype_key = REDIS_SUBTYPE_KEY % (build_id, type, subtype)

		# remove from initialization priority list
		redis_conn.hdel(type_key, subtype_key)
		redis_conn.delete(subtype_key)

	def flush_console_output(self, build_id, type, subtype=""):
		""" Flushes finalized console output to a persisted sql db.
		:param build_id: The build id this console is relevant to.
		:param type: The console type we are flushing.
		:param subtype: The console subtype we are flushing.
		"""
		"""build_console = schema.build_console

		redis_conn = ConnectionFactory.get_redis_connection()
		subtype_priority = self._get_priority(
			redis_conn, build_id, type, subtype)
		complete_console_output = self._compact_output(redis_conn,
			build_id, type, subtype)

		whereclause = and_(
			build_console.c.build_id==build_id,
			build_console.c.type==type,
			build_console.c.subtype==subtype
		)

		query = build_console.select().where(whereclause)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		if row:
			statement = build_console.update().values(
				console_output=complete_console_output,
				subtype_priority=subtype_priority).where(whereclause)
		else:
			statement = build_console.insert().values(
				build_id=build_id,
				type=type,
				subtype=subtype,
				subtype_priority=subtype_priority,
				console_output=complete_console_output)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(statement)
		self._remove_tmpdata(redis_conn, build_id, type, subtype)
		"""
		# TODO: REFACTOR ALL THIS SHIT
		pass
