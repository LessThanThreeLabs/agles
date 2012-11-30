import time

from database import schema
from database.engine import ConnectionFactory
from kombu.connection import Connection
from model_server.events_broker import EventsBroker
from model_server.rpc_handler import ModelServerRpcHandler
from settings.rabbit import connection_info


class ChangesUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ChangesUpdateHandler, self).__init__("changes", "update")

	def mark_change_finished(self, change_id, status):
		change = schema.change
		update = change.update().where(change.c.id==change_id).values(
			status=status, end_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)

		self.publish_event(change_id=change_id, status=status)
