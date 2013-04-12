from virtual_machine.remote_command import RemoteCompileCommand, RemoteTestCommand, RemotePartitionCommand

DEFAULT_PARALLELIZATION = 8

class VerificationConfig(object):
	def __init__(self, compile_commands, test_section):
		self.parallel = test_section.get('parallel', DEFAULT_PARALLELIZATION)
		test_commands = test_section.get('manual')
		partition_commands = test_section.get('automatic')
		self.compile_commands = [RemoteCompileCommand(command)
			for command in compile_commands] if compile_commands else []
		self.test_commands = [RemoteTestCommand(command)
			for command in test_commands] if test_commands else []
		self.partition_commands = [RemotePartitionCommand(command)
			for command in partition_commands] if partition_commands else []
