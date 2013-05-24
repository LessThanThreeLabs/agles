import shlex

from verification.build_core import VirtualMachineBuildCore
from virtual_machine.virtual_machine import VirtualMachine


class FakeBuildCore(VirtualMachineBuildCore):
	def __init__(self, vm_id):
		self.virtual_machine = FakeVirtualMachine(vm_id)

	def setup(self):
		pass

	def teardown(self):
		pass

	def cache_repository(self, repo_uri):
		return self.virtual_machine.call(["true"])


class FakeVirtualMachine(VirtualMachine):
	def provision(self, private_key, output_handler=None):
		return self.call(["true"])

	def ssh_call(self, command, output_handler=None, timeout=None):
		return self.call(shlex.split(command), output_handler, timeout=timeout)

	def export(self, export_prefix, files, output_handler=None):
		return self.call(["true"])
