from vagrant.vagrant_command import SimpleVagrantCompileCommand, SimpleVagrantTestCommand


class VerificationConfig(object):
	def __init__(self, compile_commands, test_commands):
		self.compile_commands = [SimpleVagrantCompileCommand(self._get_command_name(command))
			for command in compile_commands] if compile_commands else []
		self.test_commands = [SimpleVagrantTestCommand(self._get_command_name(command))
			for command in test_commands] if test_commands else []

	def _get_command_name(self, command):
		return command.iterkeys().next()
