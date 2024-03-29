import time

from shared.constants import BuildStatus
from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class BuildsUpdateHandler(ModelServerRpcHandler):

	def __init__(self, channel=None):
		super(BuildsUpdateHandler, self).__init__("builds", "update", channel)

	def start_build(self, build_id):
		build = schema.build
		update = build.update().where(build.c.id == build_id).values(
			status=BuildStatus.RUNNING, start_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(update)
		if not result.rowcount == 1:
			raise NoSuchBuildError(build_id)
		self.publish_event("builds", build_id, "build started", status=BuildStatus.RUNNING)

	def mark_build_finished(self, build_id, status):
		build = schema.build
		update = build.update().where(build.c.id == build_id).values(
			status=status, end_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(update)
		if not result.rowcount == 1:
			raise NoSuchBuildError(build_id)
		self.publish_event("builds", build_id, "build finished", status=status)

	def add_export_metadata(self, build_id, export_metadata):
		if not export_metadata:
			return

		build = schema.build
		build_export_metadata = schema.build_export_metadata

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(
				build_export_metadata.insert(),
				[{'build_id': build_id, 'uri': metadata['uri'], 'path': metadata['path']} for metadata in export_metadata]
			)
			change_id = sqlconn.execute(
				build.select().where(build.c.id == build_id)
			).first()[build.c.change_id]

		self.publish_event("changes", change_id, "export metadata added", export_metadata=export_metadata)


class NoSuchBuildError(Exception):
	pass
