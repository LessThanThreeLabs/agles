class VagrantCommand(object):
	def run(self, vagrant_wrapper, output_handler):
		raise NotImplementedError("Subclasses should override this!")


class NullVagrantCommand(VagrantCommand):
	def __init__(self, name=None):
		self.name = name

	def run(self, vagrant_wrapper, output_handler):
		return 0


class SimpleVagrantCommand(VagrantCommand):
	def __init__(self, type, name):
		super(SimpleVagrantCommand, self).__init__()
		self.type = type
		self.name = name

	def _get_command(self):
		return "scripts/%s/%s.sh" % (self.type, self.name)

	def run(self, vagrant_wrapper, output_handler):
		results = vagrant_wrapper.ssh_call(self._get_command(), output_handler)
		return results.returncode


class SimpleVagrantCompileCommand(SimpleVagrantCommand):
	def __init__(self, name):
		super(SimpleVagrantCompileCommand, self).__init__("compile", name)


class SimpleVagrantTestCommand(SimpleVagrantCommand):
	def __init__(self, name):
		super(SimpleVagrantTestCommand, self).__init__("test", name)
