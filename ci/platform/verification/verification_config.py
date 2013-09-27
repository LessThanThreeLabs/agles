import yaml

from virtual_machine.remote_command import RemoteProvisionCommand, RemoteCompileCommand, RemoteTestCommand, RemoteTestFactoryCommand, RemoteErrorCommand, RemoteCheckoutCommand, RemotePatchCommand, RemoteSshConfigCommand


class VerificationConfig(object):
	def __init__(self, repo_name, machines, setup_commands, compile_commands, test_factory_commands, test_commands, export_paths):
		self.repo_name = repo_name
		self.machines = machines
		self.setup_commands = setup_commands
		self.compile_commands = compile_commands
		self.test_factory_commands = test_factory_commands
		self.test_commands = test_commands
		self.export_paths = export_paths

	@classmethod
	def from_yaml(cls, repo_type, repo_name, repo_url, ref, environment, config_yaml, private_key=None, patch_id=None):
		def convert(command_class, repo_name, commands):
			if not commands:
				return [], []
			if isinstance(commands, str):
				return construct(command_class, repo_name, commands)
			if isinstance(commands, list):
				return convert_list(command_class, repo_name, commands)
			if isinstance(commands, dict):
				return convert_dict(command_class, repo_name, commands)
			raise InvalidConfigurationException("Unexpected type found while trying to construct %ss" % command_class.__name__)

		def construct(command_class, repo_name, config):
			try:
				return [command_class(repo_name, config)], []
			except Exception as e:
				return [], [e]

		def convert_list(command_class, repo_name, configs):
			commands, errors = [], []
			for config in configs:
				new_commands, new_errors = construct(command_class, repo_name, config)
				commands += new_commands
				errors += new_errors
			return commands, errors

		def convert_dict(command_class, repo_name, commands):
			return convert_list(command_class, repo_name, map(lambda entry: dict((entry,)), commands.iteritems()))

		def to_export_paths(export_section):
			try:
				if export_section is None:
					export_paths = []
				elif isinstance(export_section, str):
					export_paths = [export_section]
				elif isinstance(export_section, list):
					export_paths = export_section
				else:
					assert False, 'Export section must be a string or list of strings'
				assert all(map(lambda path: isinstance(path, str), export_paths)), 'Export section must be a string or list of strings'
				return export_paths, []
			except Exception as e:
				return [], [e]

		if config_yaml is None:
			return NoYamlErrorVerificationConfig()

		try:
			config = yaml.safe_load(config_yaml)
		except yaml.error.YAMLError as e:
			return InvalidYamlErrorVerificationConfig(e)

		if not isinstance(config, dict):
			return InvalidYamlErrorVerificationConfig('koality.yml must parse to a dictionary, was %s instead' % type(config).__name__)

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
		setup_commands.append(RemoteProvisionCommand(repo_name, environment, language_section, setup_section))

		if compile_section is not None and not isinstance(compile_section, dict):
			return InvalidYamlErrorVerificationConfig('"compile" section must parse to a dictionary, was %s instead' % type(compile_section).__name__)

		if test_section is not None and not isinstance(test_section, dict):
			return InvalidYamlErrorVerificationConfig('"test" section must parse to a dictionary, was %s instead' % type(test_section).__name__)

		machines = test_section.get('machines')

		if not isinstance(machines, (int, type(None))):
			return InvalidYamlErrorVerificationConfig('test->machines must be an int or be unspecified')

		compile_configs = compile_section.get('scripts') if compile_section else None
		test_configs = test_section.get('scripts') if test_section else None
		test_factory_configs = test_section.get('factories') if test_section else None

		compile_commands, compile_errors = convert(RemoteCompileCommand, repo_name, compile_configs)
		test_commands, test_errors = convert(RemoteTestCommand, repo_name, test_configs)
		test_factory_commands, test_factory_errors = convert(RemoteTestFactoryCommand, repo_name, test_factory_configs)

		export_paths, export_errors = to_export_paths(export_section)

		config_errors = compile_errors + test_errors + test_factory_errors + export_errors
		if config_errors:
			return InvalidYamlErrorVerificationConfig(config_errors)

		return cls(repo_name, machines, setup_commands, compile_commands, test_factory_commands, test_commands, export_paths)


class ErrorVerificationConfig(VerificationConfig):
	def __init__(self, error_title, error_message):
		super(ErrorVerificationConfig, self).__init__(
			repo_name='error', machines=1, setup_commands=[RemoteErrorCommand(error_title, error_message)], compile_commands=[], test_factory_commands=[], test_commands=[], export_paths=[]
		)

	def error_to_message(self, error):
		if isinstance(error, Exception):
			return '%s: %s' % (type(error).__name__, error)
		else:
			return str(error)


class ParseErrorVerificationConfig(ErrorVerificationConfig):
	def __init__(self, parse_error):
		super(ParseErrorVerificationConfig, self).__init__('parse error', self.error_to_message(parse_error))


class InvalidYamlErrorVerificationConfig(ErrorVerificationConfig):
	def __init__(self, errors):
		if not isinstance(errors, list):
			errors = [errors]

		error_message = '\n\n'.join(self.error_to_message(error) for error in errors)
		super(InvalidYamlErrorVerificationConfig, self).__init__('invalid koality.yml', error_message)


class NoYamlErrorVerificationConfig(ErrorVerificationConfig):
	def __init__(self):
		super(NoYamlErrorVerificationConfig, self).__init__(
			'missing koaliy.yml',
			'Please add a "koality.yml" or ".koality.yml" file to the root of your repository.'
		)


class InvalidConfigurationException(Exception):
	pass
