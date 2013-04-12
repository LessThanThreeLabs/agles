import os
import random
import shlex
import shutil

from verification.build_core import VirtualMachineBuildCore
#from verification.verification_config import VerificationConfig
from virtual_machine.virtual_machine import VirtualMachine


class FakeBuildCore(VirtualMachineBuildCore):
	def __init__(self):
		self.virtual_machine = FakeVirtualMachine()

	def setup(self):
		os.makedirs(self.virtual_machine.vm_directory)

	def teardown(self):
		shutil.rmtree(self.virtual_machine.vm_directory, ignore_errors=True)

	def cache_repository(self, repo_uri):
		return self.virtual_machine.call(["true"])


class FakeVirtualMachine(VirtualMachine):
	def __init__(self):
		self.vm_directory = "/tmp/fakevm_%s" % str(random.random())[2:]

	def provision(self, private_key, output_handler=None):
		return self.call(["true"])

	def ssh_call(self, command, output_handler=None, timeout=None):
		return self.call(shlex.split(command), output_handler, timeout=timeout)
