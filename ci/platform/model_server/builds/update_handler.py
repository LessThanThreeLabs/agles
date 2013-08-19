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
		update = build.update().where(build.c.id == build_id).values(
			status=BuildStatus.RUNNING, start_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(update)
		if not result.rowcount == 1:
			raise NoSuchBuildError(build_id)
		self.publish_event("builds", build_id, "build started", status=BuildStatus.RUNNING)

	def create_vm_in_db(self, vm_type, instance_id, pool_slot, username):
		virtual_machine = schema.virtual_machine

		existing_vm = virtual_machine.select().where(
			and_(
				virtual_machine.c.instance_id == instance_id,
				virtual_machine.c.deleted == 0
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			if sqlconn.execute(existing_vm).rowcount > 0:
				raise VirtualMachineAlreadyExistsError(instance_id)
			ins = virtual_machine.insert().values(
				type=vm_type,
				instance_id=instance_id,
				pool_slot=pool_slot,
				username=username)
			result = sqlconn.execute(ins)

		vm_id = result.inserted_primary_key[0]
		return vm_id

	def mark_build_finished(self, build_id, status):
		build = schema.build
		update = build.update().where(build.c.id == build_id).values(
			status=status, end_time=int(time.time()))
		with ConnectionFactory.get_sql_connection() as sqlconn:
			result = sqlconn.execute(update)
		if not result.rowcount == 1:
			raise NoSuchBuildError(build_id)
		self.publish_event("builds", build_id, "build finished", status=status)


class NoSuchBuildError(Exception):
	pass

class VirtualMachineAlreadyExistsError(Exception):
	pass
