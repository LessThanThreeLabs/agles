class BuildCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		raise NotImplementedError("Subclasses should override this!")


class NullBuildCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		return 0


class SimpleVagrantBuildCommand(BuildCommand):
	def __init__(self, language, command):
		super(SimpleVagrantBuildCommand, self).__init__()
		self.language = language
		self.command = command

	def run(self, vagrant_wrapper, output_handler):
		full_command = "source .%s.sh; cd source; %s" % (self.language, self.command)
		results = vagrant_wrapper.ssh_call(full_command, output_handler)
		return results.returncode
