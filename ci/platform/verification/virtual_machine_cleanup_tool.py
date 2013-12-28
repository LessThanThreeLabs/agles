import ast
import collections

from database.engine import ConnectionFactory


class VirtualMachineCleanupTool(object):
	def __init__(self, vm_class):
		self.vm_class = vm_class

	def cleanup(self):
		redis_conn = ConnectionFactory.get_redis_connection('virtual_machine')
		for key in redis_conn.keys('*'):
			try:
				key = ast.literal_eval(key)
				if isinstance(key, collections.Iterable) and len(key) == 2:
					vm = self.vm_class.from_vm_id(*key)
				else:
					vm = self.vm_class.from_id(key)
				vm.delete() if vm else None
			except:
				pass
