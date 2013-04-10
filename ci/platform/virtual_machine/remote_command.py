import pipes


class RemoteCommand(object):
	def run(self, virtual_machine, output_handler):
		if output_handler:
			output_handler.declare_command()
		results = self._run(virtual_machine, output_handler)
		if output_handler:
			output_handler.set_return_code(results.returncode)
		return results

	def _run(self, virtual_machine, output_handler=None):
		raise NotImplementedError("Subclasses should override this!")


class NullRemoteCommand(RemoteCommand):
	def __init__(self, name=None):
		self.name = name

	def _run(self, virtual_machine, output_handler=None):
		return {'returncode': 0,
			'output': ''}


class RemoteShellCommand(RemoteCommand):
	def __init__(self, command):
		super(RemoteShellCommand, self).__init__()
		self.name = command

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.ssh_call('bash --login -c %s' % pipes.quote(self.name), output_handler)


class RemoteScriptCommand(RemoteCommand):
	def __init__(self, type, name):
		super(RemoteScriptCommand, self).__init__()
		self.type = type
		self.name = name

	def _get_command(self):
		return "bash --login scripts/%s/%s" % (pipes.quote(self.type), pipes.quote(self.name))

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.ssh_call(self._get_command(), output_handler)


class RemoteCompileCommand(RemoteScriptCommand):
	def __init__(self, name):
		super(RemoteCompileCommand, self).__init__("compile", name)


class RemoteTestCommand(RemoteScriptCommand):
	def __init__(self, name):
		super(RemoteTestCommand, self).__init__("test", name)


class RemotePartitionCommand(RemoteScriptCommand):
	def __init__(self, name):
		super(RemotePartitionCommand, self).__init__("partition", name)


class RemoteSetupCommand(RemoteCommand):
	def __init__(self, name):
		super(RemoteSetupCommand, self).__init__()
		self.name = name


class RemoteCheckoutCommand(RemoteSetupCommand):
	def __init__(self, repo_name, git_url, ref):
		super(RemoteCheckoutCommand, self).__init__("git")
		self.git_url = git_url
		self.ref = ref
		self.repo_name = repo_name

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.remote_checkout(self.repo_name, self.git_url, self.ref, output_handler=output_handler)


class RemoteProvisionCommand(RemoteSetupCommand):
	def __init__(self, private_key):
		super(RemoteProvisionCommand, self).__init__("provision")
		self.private_key = private_key

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.provision(self.private_key, output_handler=output_handler)
