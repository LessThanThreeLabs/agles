class BuildCommand(object):
	def run(self):
		raise NotImplementedError("Subclasses should override this!")


class NullBuildCommand(object):
	def run(self):
		return 0


class SimpleVagrantBuildCommand(BuildCommand):
	def __init__(self, vagrant, command):
		super(self, BuildCommand).__init__(self)
		self.vagrant = vagrant
		self.command = command

	def run(self):
		results = self.vagrant.ssh_call(self.command)
		return results.returncode
