import database.schema

from model_server.rpc_handler import ModelServerRpcHandler


class ChangeReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ChangeReadHandler, self).__init__("change", "read")

	def get_change_attributes(self, change_id):
		change = database.schema.change
		query = change.select().where(change.c.id==change_id)
		row = self._db_conn.execute(query).first()
		if row:
			return (row[change.c.commit_id], row[change.c.merge_target],
				row[change.c.number], row[change.c.status],
				row[change.c.start_time], row[change.c.end_time])
