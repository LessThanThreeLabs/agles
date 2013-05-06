from virtual_machine.remote_command import RemoteCompileCommand, RemoteTestCommand, RemoteTestFactoryCommand, RemoteErrorCommand


class VerificationConfig(object):
	def __init__(self, compile_section, test_section):
		try:
			self.machines = test_section.get('machines')
			test_commands = test_section.get('scripts')
			test_factory_commands = test_section.get('factories')
			compile_commands = compile_section.get('scripts')
			self.compile_commands = self._convert(RemoteCompileCommand, compile_commands)
			self.test_commands = self._convert(RemoteTestCommand, test_commands)
			self.test_factory_commands = self._convert(RemoteTestFactoryCommand, test_factory_commands)
		except:
			self.machines = 1
			self.compile_commands = []
			self.test_commands = [RemoteErrorCommand("parse error", "Could not parse your koality.yml file.\nPlease verify that it is valid yaml and matches the expected format.")]
			self.test_factory_commands = []

	def _convert(self, command_class, commands):
		if not commands:
			return []
		if isinstance(commands, str):
			return command_class(commands)
		if isinstance(commands, list):
			return self._convert_list(command_class, commands)
		if isinstance(commands, dict):
			return self._convert_dict(command_class, commands)
		raise InvalidConfigurationException("Unexpected type found while trying to construct %ss" % command_class.__name__)

	def _convert_list(self, command_class, commands):
		return [command_class(command) for command in commands]

	def _convert_dict(self, command_class, commands):
		return self._convert_list(command_class, map(lambda entry: dict((entry,)), commands.iteritems()))


class InvalidConfigurationException(Exception):
	pass
