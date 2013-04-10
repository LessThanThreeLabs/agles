from virtual_machine.remote_command import RemoteCompileCommand, RemoteTestCommand, RemotePartitionCommand


class VerificationConfig(object):
	def __init__(self, compile_commands, test_commands, partition_commands):
		self.compile_commands = [RemoteCompileCommand(self._get_command_name(command))
			for command in compile_commands] if compile_commands else []
		self.test_commands = [RemoteTestCommand(self._get_command_name(command))
			for command in test_commands] if test_commands else []
		self.partition_commands = [RemotePartitionCommand(self._get_command_name(command))
			for command in partition_commands] if partition_commands else []
		self._compile_commands = compile_commands
		self._test_commands = test_commands
		self._partition_commands = partition_commands

	def _get_command_name(self, command):
		if isinstance(command, (str, unicode)):
			return command
		elif isinstance(command, dict):
			return command.iterkeys().next()

	def to_dict(self):
		return {'compile_commands': self._compile_commands,
			'test_commands': self._test_commands,
			'partition_commands': self._partition_commands}

	@classmethod
	def from_dict(cls, config_dict):
		return cls(config_dict.get('compile_commands'), config_dict.get('test_commands'), config_dict.get('partition_commands'))
