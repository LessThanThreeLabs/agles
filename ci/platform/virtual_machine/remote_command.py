class RemoteCommand(object):
	def run(self, virtual_machine, output_handler):
		raise NotImplementedError("Subclasses should override this!")


class NullRemoteCommand(RemoteCommand):
	def __init__(self, name=None):
		self.name = name

	def run(self, virtual_machine, output_handler=None):
		return 0


class SimpleRemoteCommand(RemoteCommand):
	def __init__(self, type, name):
		super(SimpleRemoteCommand, self).__init__()
		self.type = type
		self.name = name

	def _get_command(self):
		return "scripts/%s/%s.sh" % (self.type, self.name)

	def run(self, virtual_machine, output_handler=None):
		results = virtual_machine.ssh_call(self._get_command(), output_handler)
		if output_handler:
			output_handler.set_return_code(results.returncode)
		return results.returncode


class SimpleRemoteCompileCommand(SimpleRemoteCommand):
	def __init__(self, name):
		super(SimpleRemoteCompileCommand, self).__init__("compile", name)


class SimpleRemoteTestCommand(SimpleRemoteCommand):
	def __init__(self, name):
		super(SimpleRemoteTestCommand, self).__init__("test", name)


class SimpleRemoteProvisionCommand(RemoteCommand):
	def __init__(self, role=None):
		super(SimpleRemoteProvisionCommand, self).__init__()
		self.name = "chef"
		self.role = role

	def run(self, virtual_machine, output_handler=None):
		results = virtual_machine.provision(role=self.role, output_handler=output_handler)
		if output_handler:
			output_handler.set_return_code(results.returncode)
		return results.returncode
