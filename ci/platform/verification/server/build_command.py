class BuildCommand(object):
	def run(self):
		raise NotImplementedError("Subclasses should override this!")


class NullBuildCommand(object):
	def run(self):
		return 0


class SimpleVagrantBuildCommand(BuildCommand):
	def __init__(self, command):
		super(self, BuildCommand).__init__(self)
		self.command = command

	def run(self, vagrant_wrapper, output_handler):
		results = vagrant_wrapper.ssh_call(self.command, output_handler)
		return results.returncode
