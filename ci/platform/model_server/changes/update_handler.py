import time

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from shared.constants import BuildStatus


class ChangesUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ChangesUpdateHandler, self).__init__("changes", "update")

	def mark_change_started(self, change_id):
		self._update_change_status(change_id, BuildStatus.RUNNING,
			"change started", start_time=int(time.time()))

	def mark_change_finished(self, change_id, status):
		self._update_change_status(change_id, status,
			"change finished", end_time=int(time.time()))

	def _update_change_status(self, change_id, status, event_name, **kwargs):
		change = schema.change
		update = change.update().where(change.c.id==change_id).values(
			status=status, **kwargs)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)

		self.publish_event("changes", change_id, event_name, status=status, **kwargs)
