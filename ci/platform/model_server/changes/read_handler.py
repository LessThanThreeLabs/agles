import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class ChangesReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangesReadHandler, self).__init__("changes", "read")

	def get_change_attributes(self, change_id):
		change = database.schema.change
		query = change.select().where(change.c.id==change_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return (row[change.c.commit_id], row[change.c.merge_target],
				row[change.c.number], row[change.c.status],
				row[change.c.start_time], row[change.c.end_time])
