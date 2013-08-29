import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class DebugInstancesCreateHandler(ModelServerRpcHandler):
	def __init__(self, channel=None):
		super(DebugInstancesCreateHandler, self).__init__("debug_instances", "create", channel)

	def create_debug_instance(self, vm_type, instance_id, pool_slot, username):
		virtual_machine = database.schema.virtual_machine

		existing_vm = virtual_machine.select().where(virtual_machine.c.instance_id == instance_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			if sqlconn.execute(existing_vm).rowcount > 0:
				return
			ins = virtual_machine.insert().values(
				type=vm_type,
				instance_id=instance_id,
				pool_slot=pool_slot,
				username=username)
			sqlconn.execute(ins)


class VirtualMachineAlreadyExistsError(Exception):
	pass
