class VagrantCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		raise NotImplementedError("Subclasses should override this!")


class NullVagrantCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		return 0


class SimpleVagrantCommand(VagrantCommand):
	def __init__(self, type, command):
		super(SimpleVagrantCommand, self).__init__()
		self.type = type
		self.command = command

	def run(self, vagrant_wrapper, output_handler):
		full_command = "source scripts/setup.sh; scripts/%s/%s.sh" % (self.type, self.command)
		results = vagrant_wrapper.ssh_call(full_command, output_handler)
		return results.returncode


class SimpleVagrantBuildCommand(SimpleVagrantCommand):
	def __init__(self, command):
		super(SimpleVagrantBuildCommand, self).__init__("build", command)


class SimpleVagrantTestCommand(SimpleVagrantCommand):
	def __init__(self, command):
		super(SimpleVagrantTestCommand, self).__init__("test", command)
