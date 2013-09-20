import inspect
import simplejson
import os
import pipes
import model_server

from pysh.shell_tools import ShellCommand, ShellSilent, ShellAnd, ShellOr, ShellChain, ShellTest, ShellIf, ShellAdvertised, ShellLogin, ShellBackground, ShellSubshell
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
	def __init__(self, type, repo_name, step_info, advertise_commands=True):
		super(RemoteShellCommand, self).__init__()
		self.type = type
		self.repo_name = repo_name
		self.advertise_commands = advertise_commands
		self.name, self.path, self.commands, self.timeout, self.xunit = self._parse_step(step_info)

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.ssh_call(ShellLogin(self._to_script()), output_handler)

	def _parse_step(self, step):
		path = None
		timeout = 600
		xunit = None
		if isinstance(step, bool):
			step = self._bool_to_str(step)

		if isinstance(step, str):
			name = step
			commands = [step]
		elif isinstance(step, dict):
			if len(step.items()) > 1:
				raise InvalidConfigurationException("Could not parse %s step: %s" % (self.type, step))
			name = step.keys()[0]
			try:
				path, commands, timeout, xunit = self._parse_step_info(step.values()[0])
			except InvalidConfigurationException as e:
				raise InvalidConfigurationException("%s in step: %s" % (e.message, step))
			if not commands:
				commands = [name]
		else:
			raise InvalidConfigurationException("Could not parse %s step: %s" % (self.type, step))
		return name, path, commands, timeout, xunit

	def _parse_step_info(self, step_info):
		path = None
		commands = None
		timeout = 600
		xunit = None
		if isinstance(step_info, str):
			commands = [step_info]
		elif isinstance(step_info, list):
			commands = step_info
		elif isinstance(step_info, dict):
			for key, value in step_info.items():
				if key == 'script':
					commands = map(self._bool_to_str, self._listify(value))
				elif key == 'path':
					path = value
				elif key == 'timeout':
					timeout = value
				elif key == 'xunit':
					xunit = map(self._bool_to_str, self._listify(value))
				else:
					raise InvalidConfigurationException("Invalid %s option: %s" % (self.type, key))

		assert path is None or isinstance(path, str)
		assert commands is None or all(map(lambda command: isinstance(command, str), commands))
		assert isinstance(timeout, int)

		return path, commands, timeout, xunit

	def _listify(self, value):
		if isinstance(value, str):
			return [value]
		elif isinstance(value, list):
			return value
		else:
			raise InvalidConfigurationException("Could not parse %s value: %s" % (self.type, value))

	def _bool_to_str(self, value):
		assert isinstance(value, (str, bool))
		if isinstance(value, str):
			return str(value)
		elif isinstance(value, bool):
			return str(value).lower()
		else:
			assert False, "Invalid type (%s) for value %s" % (type(value).__name__, value)

	def _to_script(self):
		def advertise(command):
			return ShellAdvertised(command) if self.advertise_commands else ShellCommand(command)

		given_command = ShellCommand('eval %s' % pipes.quote(str(ShellAnd(*map(advertise, self.commands)))))

		# If timeout fails to cleanly interrupt the script in 3 seconds, we send a SIGKILL
		timeout_message = "echo %s timed out after %s seconds" % (pipes.quote(self.name), self.timeout)

		timeout_command = ShellChain(
			ShellCommand('sleep %s' % self.timeout),
			ShellSilent('kill -INT $$'),
			ShellCommand('sleep 1'),
			ShellIf(
				ShellSilent('kill -0 $$'),
				ShellChain(
					ShellCommand('sleep 2'),
					ShellSilent('kill -KILL $$'),
					ShellCommand('echo'),
					timeout_message,
					ShellCommand('kill -9 0')
				),
				ShellChain(
					ShellCommand('echo'),
					timeout_message,
					ShellCommand('kill -9 0')
				)
			)
		)

		commands_with_timeout = ShellChain(
			ShellBackground(ShellSilent(ShellSubshell(timeout_command))),
			ShellCommand('watchdogpid=$!'),
			given_command,
			ShellCommand('_r=$?'),
			ShellCommand('exec 2>/dev/null'),  # goodbye stderr stream
			ShellSilent('kill -KILL $watchdogpid'),  # kill the timeout process
			ShellSilent('pkill -KILL -P $watchdogpid'),  # kill all children of the timeout process
			ShellOr(
				ShellTest('$_r -eq 0'),
				ShellCommand('echo %s failed with return code $_r' % pipes.quote(self.name))
			),
			ShellCommand('exit $_r')
		)

		return ShellAnd(
			advertise('cd %s' % (os.path.join(self.repo_name, self.path) if self.path else self.repo_name)),
			commands_with_timeout
		)


class RemoteCompileCommand(RemoteShellCommand):
	def __init__(self, repo_name, compile_step):
		super(RemoteCompileCommand, self).__init__("compile", repo_name, compile_step)


class RemoteTestCommand(RemoteShellCommand):
	def __init__(self, repo_name, test_step):
		super(RemoteTestCommand, self).__init__("test", repo_name, test_step)

	def get_xunit_contents(self):
		pass

	def _run(self, virtual_machine, output_handler=None):
		retval = super(RemoteTestCommand, self)._run(virtual_machine, output_handler)
		if self.xunit:
			def new_xunit_contents():
				if self.path:
					xunit_paths = [os.path.join(self.repo_name, self.path, xunit) for xunit in self.xunit]
				else:
					xunit_paths = [os.path.join(self.repo_name, xunit) for xunit in self.xunit]
				results = virtual_machine.ssh_call(
					'python -c %s' % pipes.quote(self._get_xunit_contents_script(xunit_paths)))
				try:
					return simplejson.loads(results.output)
				except:
					return None
			self.get_xunit_contents = new_xunit_contents
		return retval

	def _get_xunit_contents_script(self, xunit_paths):
		def read_xunit_contents(xunit_paths):
			import os, os.path, json

			files = []
			for xunit_path in xunit_paths:
				if os.path.isfile(xunit_path):
					files.append(xunit_path)
				else:
					for root, dirs, dirfiles in os.walk(xunit_path):
						files.extend([os.path.join(root, dirfile) for dirfile in dirfiles if dirfile.endswith('.xml')])

			contents = {}
			for file in files:
				with open(file) as f:
					file_contents = f.read().strip()
					if file_contents:
						contents[file] = file_contents

			print json.dumps(contents)

		function_source = inspect.getsource(read_xunit_contents)
		leading_spaces = len(function_source) - len(function_source.lstrip())
		sanitized_source = '\n'.join(map(lambda line: line[leading_spaces:], function_source.split('\n')))
		return '%s\n%s(%s)' % (sanitized_source, read_xunit_contents.func_name, xunit_paths)


class RemoteTestFactoryCommand(RemoteShellCommand):
	def __init__(self, repo_name, test_factory_step):
		super(RemoteTestFactoryCommand, self).__init__("test factory", repo_name, test_factory_step, advertise_commands=False)


class RemoteSetupCommand(RemoteCommand):
	def __init__(self, name):
		super(RemoteSetupCommand, self).__init__()
		self.name = name


class RemoteSshConfigCommand(RemoteSetupCommand):
	def __init__(self, private_key):
		super(RemoteSshConfigCommand, self).__init__('ssh-config')
		self.private_key = private_key

	def run(self, virtual_machine, output_handler=None):
		# Explicitly ignore the output handler. We don't want to display this to the users.
		return super(RemoteSshConfigCommand, self).run(virtual_machine)

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.configure_ssh(self.private_key, output_handler=output_handler)


class RemoteCheckoutCommand(RemoteSetupCommand):
	def __init__(self, repo_name, repo_url, repo_type, ref):
		super(RemoteCheckoutCommand, self).__init__(repo_type)
		self.repo_url = repo_url
		self.repo_type = repo_type
		self.ref = ref
		self.repo_name = repo_name

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.remote_checkout(self.repo_name, self.repo_url, self.repo_type, self.ref, output_handler=output_handler)


class RemotePatchCommand(RemoteSetupCommand):
	def __init__(self, repo_name, patch_id):
		super(RemotePatchCommand, self).__init__('patch')
		with model_server.rpc_connect('changes', 'read') as client:
			patch = client.get_patch(patch_id)
		self.patch_contents = str(patch['contents']) if patch else None
		self.repo_name = repo_name

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.remote_patch(self.repo_name, self.patch_contents, output_handler=output_handler)


class RemoteProvisionCommand(RemoteSetupCommand):
	def __init__(self, repo_name, environment, language_config, setup_config):
		super(RemoteProvisionCommand, self).__init__('provision')
		self.repo_name = repo_name
		self.environment = environment
		self.language_config = language_config
		self.setup_config = setup_config

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.provision(self.repo_name, self.environment, self.language_config, self.setup_config, output_handler=output_handler)


class RemoteExportCommand(RemoteCommand):
	def __init__(self, repo_name, export_prefix, file_paths):
		super(RemoteCommand, self).__init__()
		self.name = 'export'
		self.repo_name = repo_name
		self.export_prefix = export_prefix
		self.file_paths = file_paths

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.export(self.repo_name, self.export_prefix, self.file_paths, output_handler=output_handler)


class RemoteErrorCommand(RemoteCommand):
	def __init__(self, name, error_message):
		super(RemoteErrorCommand, self).__init__()
		self.name = name
		self.error_message = error_message

	def _run(self, virtual_machine, output_handler=None):
		full_message = 'Error: %s' % self.error_message
		return virtual_machine.ssh_call("echo -e %s; exit 1" % pipes.quote(full_message), output_handler=output_handler)

	def get_xunit_contents(self):
		pass

class InvalidConfigurationException(Exception):
	pass
