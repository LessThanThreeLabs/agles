from vagrant.vagrant_command import SimpleVagrantBuildCommand, SimpleVagrantTestCommand


class VerificationConfig(object):
	def __init__(self, build_commands, test_commands):
		self.build_commands = [SimpleVagrantBuildCommand(name)
			for name in build_commands.iterkeys()] if build_commands else []
		self.test_commands = [SimpleVagrantTestCommand(name)
			for name in test_commands.iterkeys()] if test_commands else []
