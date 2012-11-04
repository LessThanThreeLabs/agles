class BuildCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		raise NotImplementedError("Subclasses should override this!")


class NullBuildCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		return 0


class SimpleVagrantBuildCommand(BuildCommand):
	def __init__(self, language, command, path=None):
		super(SimpleVagrantBuildCommand, self).__init__()
		self.language = language
		self.command = command
		self.path = path

	def run(self, vagrant_wrapper, output_handler):
		full_path = "source/%s" % self.path if self.path else "source"
		user_command = ' '.join(map(lambda string: "\\\"%s\\\"" % string, self.command))
		print user_command
		validator_command = "echo %s| xargs ~/.validator.sh" % user_command
		print validator_command
		full_command = "source .%s.sh; cd %s; %s" % (self.language, full_path, validator_command)
		results = vagrant_wrapper.ssh_call(full_command, output_handler)
		return results.returncode
