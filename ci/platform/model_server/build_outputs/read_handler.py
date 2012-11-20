import database.schema

from sqlalchemy import and_

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from model_server.build_outputs import REDIS_TYPE_KEY, parse_subtype
from util.permissions import RepositoryPermissions

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

	def _get_subtype_priority_from_redis(self, type_key):
		redis_conn = ConnectionFactory.get_redis_connection()

		subtype_to_priority = redis_conn.hgetall(type_key)
		priority_map = dict([(parse_subtype(k), int(v))
							 for k, v in subtype_to_priority.items()])
		return priority_map

	def _get_output_from_redis(self, type_key):
		subtype_to_output = {}
		redis_conn = ConnectionFactory.get_redis_connection()
		subtype_keys = redis_conn.hgetall(type_key)
		for subtype_key in subtype_keys:
			subtype = parse_subtype(subtype_key)
			lines = dict([(int(k), v)
						  for k, v in redis_conn.hgetall(subtype_key).items()])
			subtype_to_output[subtype] = lines
		return subtype_to_output

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

	def get_subtype_priority(self, user_id, build_id, console):
		if not self._has_permission(user_id, build_id):
			return {}

		type_key = REDIS_TYPE_KEY % (build_id, console)

		redis_conn = ConnectionFactory.get_redis_connection()
		if redis_conn.exists(type_key):
			return self._get_subtype_priority_from_redis(type_key)

		build_console = database.schema.build_console
		query = self._subtypes_query(user_id, build_id, console)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return dict(
				[(row[build_console.c.subtype], row[build_console.c.priority])
					for row in sqlconn.execute(query)]
			)

	def get_console_output(self, user_id, build_id, console):
		if not self._has_permission(user_id, build_id):
			return {}

		type_key = REDIS_TYPE_KEY % (build_id, console)

		redis_conn = ConnectionFactory.get_redis_connection()
		if redis_conn.exists(type_key):
			return self._get_output_from_redis(type_key)

		build_console = database.schema.build_console
		query = self._subtypes_query(build_id, console)
		print query
		with ConnectionFactory.get_sql_connection() as sqlconn:
			subtype_to_output = {}
			for row in sqlconn.execute(query):
				lines = row[build_console.c.console_output].splitlines()
				numbered_lines = dict(enumerate(lines))
				subtype_to_output[row[build_console.c.subtype]] = numbered_lines
			return subtype_to_output