from virtual_machine.remote_command import SimpleRemoteCompileCommand, SimpleRemoteTestCommand


class VerificationConfig(object):
	def __init__(self, compile_commands, test_commands):
		self.compile_commands = [SimpleRemoteCompileCommand(self._get_command_name(command))
			for command in compile_commands] if compile_commands else []
		self.test_commands = [SimpleRemoteTestCommand(self._get_command_name(command))
			for command in test_commands] if test_commands else []

	def _get_command_name(self, command):
		return command.iterkeys().next()
