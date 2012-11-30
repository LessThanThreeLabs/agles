import time

from shared.constants import BuildStatus
from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class BuildsUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(BuildsUpdateHandler, self).__init__("builds", "update")

	def start_build(self, build_id):
		build = schema.build
		update = build.update().where(build.c.id==build_id).values(
			status=BuildStatus.RUNNING, start_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event(build_id=build_id, status=BuildStatus.RUNNING)

	def mark_build_finished(self, build_id, status):
		build = schema.build
		update = build.update().where(build.c.id==build_id).values(
			status=status, end_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event(build_id=build_id, status=status)
