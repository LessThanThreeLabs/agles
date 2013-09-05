from virtual_machine.remote_command import RemoteCompileCommand, RemoteTestCommand, RemoteTestFactoryCommand, RemoteErrorCommand


class VerificationConfig(object):
	def __init__(self, repo_name, compile_section, test_section, export_section):
		try:
			self.repo_name = repo_name
			self.machines = test_section.get('machines')
			compile_commands = compile_section.get('scripts') if compile_section else None
			test_commands = test_section.get('scripts') if test_section else None
			test_factory_commands = test_section.get('factories') if test_section else None
			self.compile_commands = self._convert(RemoteCompileCommand, compile_commands)
			self.test_commands = self._convert(RemoteTestCommand, test_commands)
			self.test_factory_commands = self._convert(RemoteTestFactoryCommand, test_factory_commands)
			if export_section is None:
				self.export_paths = []
			elif isinstance(export_section, str):
				self.export_paths = [export_section]
			elif isinstance(export_section, list):
				self.export_paths = export_section
			else:
				assert False, 'Export section must be a string or list of strings'
			assert all(map(lambda path: isinstance(path, str), self.export_paths)), 'Export section must be a string or list of strings'
		except:
			self.machines = 1
			self.compile_commands = []
			self.test_commands = [RemoteErrorCommand("parse error", "Could not parse your koality.yml file.\nPlease verify that it is valid yaml and matches the expected format.")]
			self.test_factory_commands = []
			self.export_paths = []

	def _convert(self, command_class, commands):
		if not commands:
			return []
		if isinstance(commands, str):
			return command_class(self.repo_name, commands)
		if isinstance(commands, list):
			return self._convert_list(command_class, commands)
		if isinstance(commands, dict):
			return self._convert_dict(command_class, commands)
		raise InvalidConfigurationException("Unexpected type found while trying to construct %ss" % command_class.__name__)

	def _convert_list(self, command_class, commands):
		return [command_class(self.repo_name, command) for command in commands]

	def _convert_dict(self, command_class, commands):
		return self._convert_list(command_class, map(lambda entry: dict((entry,)), commands.iteritems()))


class InvalidConfigurationException(Exception):
	pass
