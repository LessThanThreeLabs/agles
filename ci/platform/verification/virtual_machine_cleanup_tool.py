from database.engine import ConnectionFactory


class VirtualMachineCleanupTool(object):
	def __init__(self, vm_class):
		self.vm_class = vm_class

	def cleanup(self):
		with ConnectionFactory.get_redis_connection('virtual_machine') as redis_conn:
			for key in redis_conn.keys('*'):
				try:
					vm = self.vm_class.from_vm_id(key)
					vm.delete() if vm else None
				except:
					pass
