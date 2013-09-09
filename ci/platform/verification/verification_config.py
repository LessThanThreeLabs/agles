from virtual_machine.remote_command import RemoteProvisionCommand, RemoteCompileCommand, RemoteTestCommand, RemoteTestFactoryCommand, RemoteErrorCommand, RemoteCheckoutCommand, RemotePatchCommand, RemoteSshConfigCommand


class VerificationConfig(object):
	def __init__(self, repo_type, repo_name, repo_url, ref, configuration, private_key=None, patch_id=None):
		try:
			self.repo_name = repo_name

			config = configuration or {}
			language_section = config.get('languages')
			setup_section = config.get('setup')
			compile_section = config.get('compile')
			test_section = config.get('test')
			export_section = config.get('export')

			setup_commands = []
			if private_key is not None:
				setup_commands.append(RemoteSshConfigCommand(private_key))
			setup_commands.append(RemoteCheckoutCommand(repo_name, repo_url, repo_type, ref))
			if patch_id is not None:
				setup_commands.append(RemotePatchCommand(repo_name, patch_id))
			setup_commands.append(RemoteProvisionCommand(repo_name, language_section, setup_section))

			self.setup_commands = setup_commands

			self.machines = test_section.get('machines')

			compile_commands = compile_section.get('scripts') if compile_section else None
			test_commands = test_section.get('scripts') if test_section else None
			test_factory_commands = test_section.get('factories') if test_section else None

			self.compile_commands = self._convert(RemoteCompileCommand, compile_commands)
			self.test_commands = self._convert(RemoteTestCommand, test_commands)
			self.test_factory_commands = self._convert(RemoteTestFactoryCommand, test_factory_commands)

			self.export_paths = self._to_export_paths(export_section)
		except:
			self.machines = 1
			# TODO (bbland): record all failures and display this nicely to the users
			self.setup_commands = [RemoteErrorCommand("parse error", "Could not parse your koality.yml file.\nPlease verify that it is valid yaml and matches the expected format.")]
			self.compile_commands = []
			self.test_commands = []
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

	def _to_export_paths(self, export_section):
		if export_section is None:
			export_paths = []
		elif isinstance(export_section, str):
			export_paths = [export_section]
		elif isinstance(export_section, list):
			export_paths = export_section
		else:
			assert False, 'Export section must be a string or list of strings'
		assert all(map(lambda path: isinstance(path, str), export_paths)), 'Export section must be a string or list of strings'
		return export_paths


class InvalidConfigurationException(Exception):
	pass
