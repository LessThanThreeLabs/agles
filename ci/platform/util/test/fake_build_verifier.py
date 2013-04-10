import os
import random
import shutil

from verification.build_verifier import BuildVerifier
from verification.verification_config import VerificationConfig


class FakeBuildVerifier(BuildVerifier):
	def __init__(self, passes):
		super(FakeBuildVerifier, self).__init__(FakeBuildCore(passes))

	def _setup(self, build_id, verification_config):
		os.makedirs(self.build_core.virtual_machine.vm_directory)
		super(FakeBuildVerifier, self)._setup(build_id, verification_config)

	def _teardown(self):
		self.build_core.teardown()

	def teardown(self):
		self._teardown()


class FakeBuildCore(object):
	def __init__(self, passes):
		self.virtual_machine = FakeVirtualMachine()
		self.passes = passes

	def setup(self):
		pass

	def setup_build(self, repo_uri, refs, private_key, console_appender=None):
		return VerificationConfig(None, None, None)

	def run_compile_step(self, compile_commands, console_appender=None):
		pass

	def run_test_command(self, test_command, console_appender=None):
		if not self.passes:
			raise Exception()

	def run_partition_command(self, partition_command, console_appender=None):
		if not self.passes:
			raise Exception()

	def teardown(self):
		shutil.rmtree(self.virtual_machine.vm_directory, ignore_errors=True)


class FakeVirtualMachine(object):
	def __init__(self):
		self.vm_directory = "/tmp/fakevm_%s" % str(random.random())[2:]
