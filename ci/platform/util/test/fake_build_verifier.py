import os
import random
import shutil

from shared.constants import BuildStatus
from verification.shared.verification_config import VerificationConfig


class FakeBuildVerifier(object):
	def __init__(self, passes):
		self.passes = passes
		self.virtual_machine = FakeVirtualMachine()

	def setup(self):
		os.makedirs(self.virtual_machine.vm_directory)

	def teardown(self):
		shutil.rmtree(self.virtual_machine.vm_directory)

	def verify(self, repo_uri, refs, callback, console_appender=None):
		if self.passes:
			callback(BuildStatus.PASSED)
		else:
			callback(BuildStatus.FAILED)

	def setup_build(self, repo_uri, refs, private_key, console_appender=None):
		return VerificationConfig(None, None)

	def declare_commands(self, console_appender, console_type, commands):
		pass

	def run_compile_step(self, compile_commands, console_appender=None):
		pass

	def run_test_command(self, test_command, console_appender=None):
		if not self.passes:
			raise Exception()

	def mark_success(self, callback):
		callback(BuildStatus.PASSED)

	def mark_failure(self, callback):
		callback(BuildStatus.FAILED)


class FakeVirtualMachine(object):
	def __init__(self):
		self.vm_directory = "/tmp/fakevm_%s" % str(random.random())[2:]
