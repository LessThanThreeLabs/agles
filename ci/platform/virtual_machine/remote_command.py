import os
import pipes

from shared import constants
from streaming_executor import CommandResults


class RemoteCommand(object):
	def run(self, virtual_machine, output_handler=None):
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
		return CommandResults(0, '')


class RemoteShellCommand(RemoteCommand):
	def __init__(self, type, step_info, advertise_commands=True):
		super(RemoteShellCommand, self).__init__()
		self.type = type
		self.advertise_commands = advertise_commands
		self.name, self.path, self.commands, self.timeout, self.export = self._parse_step(step_info)

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.ssh_call('bash --login -c %s' % pipes.quote(self._to_script()), output_handler)

	def _parse_step(self, step):
		path = None
		timeout = 600
		if isinstance(step, str):
			name = step
			commands = [step]
		elif isinstance(step, dict):
			if len(step.items()) > 1:
				raise InvalidConfigurationException("Could not parse %s step: %s" % (self.step_type, step))
			name = step.keys()[0]
			path, commands, timeout, export = self._parse_step_info(step.values()[0])
			if not commands:
				commands = [name]
		else:
			raise InvalidConfigurationException("Could not parse %s step: %s" % (self.step_type, step))
		return name, path, commands, timeout, export

	def _parse_step_info(self, step_info):
		path = None
		commands = None
		timeout = 600
		export = None
		if isinstance(step_info, str):
			commands = [step_info]
		elif isinstance(step_info, dict):
			for key, value in step_info.items():
				if key == 'script':
					commands = self._listify(value)
				elif key == 'path':
					path = value
				elif key == 'timeout':
					timeout = value
				elif key == 'export':
					export = self._listify(value)
				else:
					raise InvalidConfigurationException("Invalid %s option: %s" % (self.step_type, key))
		return path, commands, timeout, export

	def _listify(self, value):
		if isinstance(value, str):
			return [value]
		elif isinstance(value, list):
			return value
		else:
			raise InvalidConfigurationException("Could not parse %s value: %s" % (self.step_type, value))

	def _to_script(self):
		script = self._to_executed_script()
		script += "exit $_r"
		return script

	def _to_executed_script(self):
		full_command = "&&\n".join(map(self._advertised_command, self.commands))
		script = "%s\n" % self._advertised_command("cd %s" % (os.path.join('source', self.path) if self.path else 'source'))
		script += "timeout -s INT -k 3 %d bash --login -c %s\n" % (self.timeout, pipes.quote(full_command))
		script += "_r=$?\n"
		script += "if [ $_r -eq 124 ]; then sleep 2; echo; echo %s timed out after %s seconds;\n" % (self.name, self.timeout)
		script += "elif [ $_r -ne 0 ]; then echo; echo %s failed with return code $_r; fi\n" % self.name
		return script

	def _advertised_command(self, command):
		if self.advertise_commands:
			return "echo -e $ %s &&\n%s" % (pipes.quote(command), command)
		return command


class RemoteCompileCommand(RemoteShellCommand):
	def __init__(self, compile_step):
		super(RemoteCompileCommand, self).__init__("compile", compile_step)

	def _to_script(self):
		script = self._to_executed_script()

		if self.export:
			export_directory = pipes.quote(os.path.join(constants.KOALITY_EXPORT_PATH, 'compile', self.name))
			script += "mkdir -p %s\n" % export_directory
			for export in self.export:
				export = pipes.quote(export)
				script += "ln -s %s %s\n" % (os.path.join('source', export), os.path.join(export_directory, export))

		script = script + "exit $_r"
		return script


class RemoteTestCommand(RemoteShellCommand):
	def __init__(self, test_step):
		super(RemoteTestCommand, self).__init__("test", test_step)

	def _to_script(self):
		script = self._to_executed_script()

		if self.export:
			for export in self.export:
				export = pipes.quote(os.path.join('source', export))
				export_directory = pipes.quote(os.path.join(constants.KOALITY_EXPORT_PATH, 'test', self.name))
				script += "mkdir -p %s;" % export_directory
				script += "if [ -d %s ]; then mv %s %s; mkdir -p %s\n" % (export, export, export_directory, export)
				script += "else; mv %s %s; fi\n" % (export, export_directory)

		script = script + "exit $_r"
		return script


class RemoteTestFactoryCommand(RemoteShellCommand):
	def __init__(self, partition_step):
		super(RemoteTestFactoryCommand, self).__init__("partition", partition_step, advertise_commands=False)


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


class RemoteExportCommand(RemoteCommand):
	def __init__(self, export_prefix, files):
		super(RemoteCommand, self).__init__()
		self.name = 'export'
		self.export_prefix = export_prefix
		self.files = files

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.export(self.export_prefix, self.files, output_handler=output_handler)


class RemoteErrorCommand(RemoteCommand):
	def __init__(self, name, error_message):
		super(RemoteErrorCommand, self).__init__()
		self.name = name
		self.error_message = error_message

	def _run(self, virtual_machine, output_handler=None):
		full_message = 'Error: %s' % self.error_message
		return virtual_machine.ssh_call("echo -e %s; exit 1" % pipes.quote(full_message), output_handler=output_handler)


class InvalidConfigurationException(Exception):
	pass
