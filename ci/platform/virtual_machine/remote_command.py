class RemoteCommand(object):
	def run(self, virtual_machine, output_handler):
		if output_handler:
			output_handler.declare_command()
		results = self._run(virtual_machine, output_handler)
		if output_handler:
			output_handler.set_return_code(results.returncode)
		return results.returncode

	def _run(self, virtual_machine, output_handler=None):
		raise NotImplementedError("Subclasses should override this!")


class NullRemoteCommand(RemoteCommand):
	def __init__(self, name=None):
		self.name = name

	def _run(self, virtual_machine, output_handler=None):
		return 0


class SimpleRemoteCommand(RemoteCommand):
	def __init__(self, type, name):
		super(SimpleRemoteCommand, self).__init__()
		self.type = type
		self.name = name

	def _get_command(self):
		return "bash --login scripts/%s/%s" % (self.type, self.name.replace(" ", "\ "))

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.ssh_call(self._get_command(), output_handler)


class SimpleRemoteCompileCommand(SimpleRemoteCommand):
	def __init__(self, name):
		super(SimpleRemoteCompileCommand, self).__init__("compile", name)


class SimpleRemoteTestCommand(SimpleRemoteCommand):
	def __init__(self, name):
		super(SimpleRemoteTestCommand, self).__init__("test", name)


class SimpleRemoteSetupCommand(RemoteCommand):
	def __init__(self, name):
		super(SimpleRemoteSetupCommand, self).__init__()
		self.name = name


class SimpleRemoteCheckoutCommand(SimpleRemoteSetupCommand):
	def __init__(self, repo_name, git_url, ref):
		super(SimpleRemoteCheckoutCommand, self).__init__("git")
		self.git_url = git_url
		self.ref = ref
		self.repo_name = repo_name

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.remote_checkout(self.repo_name, self.git_url, self.ref, output_handler=output_handler)


class SimpleRemoteProvisionCommand(SimpleRemoteSetupCommand):
	def __init__(self, private_key):
		super(SimpleRemoteProvisionCommand, self).__init__("provision")
		self.private_key = private_key

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.provision(self.private_key, output_handler=output_handler)
