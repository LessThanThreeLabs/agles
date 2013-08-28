import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict


class DebugInstancesReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(DebugInstancesReadHandler, self).__init__("debug_instances", "read")

	def get_vm_from_instance_id(self, instance_id):
		virtual_machine = database.schema.virtual_machine

		query = virtual_machine.select().where(virtual_machine.c.instance_id == instance_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return to_dict(row, virtual_machine.columns)
