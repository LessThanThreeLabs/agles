class VagrantCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		raise NotImplementedError("Subclasses should override this!")


class NullVagrantCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		return 0


class SimpleVagrantCommand(VagrantCommand):
	def __init__(self, type, name):
		super(SimpleVagrantCommand, self).__init__()
		self.type = type
		self.name = name

	def run(self, vagrant_wrapper, output_handler):
		full_command = "scripts/%s/%s.sh" % (self.type, self.name)
		results = vagrant_wrapper.ssh_call(full_command, output_handler)
		return results.returncode


class SimpleVagrantCompileCommand(SimpleVagrantCommand):
	def __init__(self, name):
		super(SimpleVagrantCompileCommand, self).__init__("compile", name)


class SimpleVagrantTestCommand(SimpleVagrantCommand):
	def __init__(self, name):
		super(SimpleVagrantTestCommand, self).__init__("test", name)
