from virtual_machine.remote_command import RemoteCompileCommand, RemoteTestCommand, RemoteTestFactoryCommand, RemoteErrorCommand


class VerificationConfig(object):
	def __init__(self, compile_section, test_section):
		try:
			self.machines = test_section.get('machines')
			test_commands = test_section.get('scripts')
			test_factory_commands = test_section.get('factories')
			compile_commands = compile_section.get('scripts')
			self.compile_commands = [RemoteCompileCommand(command)
				for command in compile_commands] if compile_commands else []
			self.test_commands = [RemoteTestCommand(command)
				for command in test_commands] if test_commands else []
			self.test_factory_commands = [RemoteTestFactoryCommand(command)
				for command in test_factory_commands] if test_factory_commands else []
		except:
			self.machines = 1
			self.compile_commands = []
			self.test_commands = [RemoteErrorCommand("Parsing Error", "Could not parse your koality.yml file.\nPlease verify that it is valid yaml and matches the expected format.")]
