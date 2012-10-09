import time

from database import schema
from model_server.rpc_handler import ModelServerRpcHandler


class ChangeUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ChangeUpdateHandler, self).__init__("change", "update")

	def mark_change_finished(self, change_id, status):
		change = schema.change
		update = change.update().where(change.c.id==change_id).values(
			status=status, end_time=int(time.time()))
		self._db_conn.execute(update)
