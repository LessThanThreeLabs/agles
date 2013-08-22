import simplejson
import os
import pipes
import model_server

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
		self.name, self.path, self.commands, self.timeout, self.export, self.xunit = self._parse_step(step_info)

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.ssh_call('bash --login -c %s' % pipes.quote(self._to_script()), output_handler)

	def _parse_step(self, step):
		path = None
		timeout = 600
		export = None
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
				path, commands, timeout, export, xunit = self._parse_step_info(step.values()[0])
			except InvalidConfigurationException as e:
				raise InvalidConfigurationException("%s in step: %s" % (e.message, step))
			if not commands:
				commands = [name]
		else:
			raise InvalidConfigurationException("Could not parse %s step: %s" % (self.type, step))
		return name, path, commands, timeout, export, xunit

	def _parse_step_info(self, step_info):
		path = None
		commands = None
		timeout = 600
		export = None
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
				elif key == 'export':
					export = map(self._bool_to_str, self._listify(value))
				elif key == 'xunit':
					export = map(self._bool_to_str, self._listify(value))
				else:
					raise InvalidConfigurationException("Invalid %s option: %s" % (self.type, key))

		assert path is None or isinstance(path, str)
		assert commands is None or all(map(lambda command: isinstance(command, str), commands))
		assert isinstance(timeout, int)
		assert export is None or all(map(lambda path: isinstance(path, str), export))

		return path, commands, timeout, export, xunit

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
			return str
		elif isinstance(value, bool):
			return str(value).lower()
		else:
			assert False, "Invalid type (%s) for value %s" % (type(value).__name__, value)

	def _to_script(self):
		script = self._to_executed_script()
		script += "exit $_r"
		return script

	def _to_executed_script(self):
		full_command = "eval %s" % pipes.quote("&&\n".join(map(self._advertised_command, self.commands)))
		script = "%s\n" % self._advertised_command("cd %s" % (os.path.join('source', self.path) if self.path else 'source'))
		# If timeout fails to cleanly interrupt the script in 3 seconds, we send a SIGKILL
		timeout_message = "echo %s timed out after %s seconds" % (pipes.quote(self.name), self.timeout)
		timeout_command = "\n".join((
			"sleep %s" % self.timeout,
			"kill -INT $$ > /dev/null 2>&1",
			"sleep 1",  # let the process die
			"if kill -0 $$ > /dev/null 2>&1",  # check if the process is still running
			"then sleep 2; kill -KILL $$ > /dev/null 2>&1; echo; %s; kill -9 0" % timeout_message,  # kill forcefully
			"else echo; %s; kill -9 0" % timeout_message,
			"fi"
		))
		commands_with_timeout = "\n".join((
			"(%s) > /dev/null 2>&1 &" % pipes.quote(timeout_command),
			"watchdogpid=$!",
			full_command,
			"_r=$?",
			"exec 2>/dev/null",  # goodbye stderr stream
			"kill -KILL $watchdogpid > /dev/null 2>&1",  # kill our timeout process
			"pkill -KILL -P $watchdogpid >/dev/null 2>&1",  # kill all children of the timeout process
			"if [ $_r -ne 0 ]; then echo %s failed with return code $_r; fi" % pipes.quote(self.name),
			"exit $_r"
		))
		script += "(%s)\n" % commands_with_timeout
		script += "_r=$?\n"
		return script

	def _advertised_command(self, command):
		if self.advertise_commands:
			advertised_command = '$ ' + '\n> '.join(command.split('\n'))
			return "echo -e %s &&\n%s" % (pipes.quote(advertised_command), command)
		return command


class RemoteCompileCommand(RemoteShellCommand):
	def __init__(self, compile_step):
		super(RemoteCompileCommand, self).__init__("compile", compile_step)

	def _to_script(self):
		script = self._to_executed_script()

		if self.export:
			export_directory = os.path.join(constants.KOALITY_EXPORT_PATH, 'compile', self.name)
			for export in self.export:
				export_parent = os.path.dirname(export.strip(os.path.sep))
				script += "cd; mkdir -p %s\n" % pipes.quote(os.path.join(export_directory, export_parent))
				script += "ln -s $(pwd)/%s %s\n" % (
					pipes.quote(os.path.join('source', export)),
					pipes.quote(os.path.join(export_directory, export))
				)

		script = script + "exit $_r"
		return script


class RemoteTestCommand(RemoteShellCommand):
	def __init__(self, test_step):
		super(RemoteTestCommand, self).__init__("test", test_step)

	def get_xunit_contents(self):
		pass

	def _run(self, virtual_machine, output_handler=None):
		retval = super(RemoteTestCommand, self)._run(virtual_machine, output_handler)
		if self.xunit:
			def new_xunit_contents():
				if self.path:
					xunit_paths = [os.path.join('source', self.path, xunit) for xunit in self.xunit]
				else:
					xunit_paths = [os.path.join('source', xunit) for xunit in self.xunit]
				results = virtual_machine.ssh_call(
					"python - <<'EOF'\n%s\nEOF" % self._get_xunit_contents_script(xunit_paths))
				return simplejson.loads(results.output)
			self.get_xunit_contents = new_xunit_contents
		return retval

	def _get_xunit_contents_script(self, xunit_paths):
		pythonc_func = """import os, os.path, json

files = []
for xunit_path in %s:
	if os.path.isfile(xunit_path):
		files.append(xunit_path)
	else:
		for root, dirs, dirfiles in os.walk(xunit_path):
			files.extend([os.path.join(root, dirfile) for dirfile in dirfiles if dirfile.endswith('.xml')])

contents = {}
for file in files:
	with open(file) as f:
		contents[file] = f.read()

print json.dumps(contents)"""
		return pythonc_func % xunit_paths

	def _to_script(self):
		script = self._to_executed_script()

		if self.export:
			for export in self.export:
				export_parent = os.path.dirname(export.strip(os.path.sep))
				export_directory = os.path.join(constants.KOALITY_EXPORT_PATH, 'test', self.name)
				script += "cd; mkdir -p %s\n" % pipes.quote(os.path.join(export_directory, export_parent))
				script += "if [ -d %s ]; then mv %s %s; mkdir -p %s\n" % (
					pipes.quote(os.path.join('source', export)),
					pipes.quote(os.path.join('source', export)), pipes.quote(os.path.join(export_directory, export)),
					pipes.quote(os.path.join('source', export))
				)
				script += "else mv %s %s; fi\n" % (
					pipes.quote(os.path.join('source', export)),
					pipes.quote(os.path.join(export_directory, export))
				)

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
	def __init__(self, repo_name, repo_url, repo_type, ref):
		super(RemoteCheckoutCommand, self).__init__(repo_type)
		self.repo_url = repo_url
		self.repo_type = repo_type
		self.ref = ref
		self.repo_name = repo_name

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.remote_checkout(self.repo_name, self.repo_url, self.repo_type, self.ref, output_handler=output_handler)


class RemotePatchCommand(RemoteSetupCommand):
	def __init__(self, patch_id):
		super(RemotePatchCommand, self).__init__('patch')
		with model_server.rpc_connect('changes', 'read') as client:
			patch = client.get_patch(patch_id)
		self.patch_contents = str(patch['contents']) if patch else None

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.remote_patch(self.patch_contents, output_handler=output_handler)


class RemoteProvisionCommand(RemoteSetupCommand):
	def __init__(self, private_key):
		super(RemoteProvisionCommand, self).__init__("provision")
		self.private_key = private_key

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.provision(self.private_key, output_handler=output_handler)


class RemoteExportCommand(RemoteCommand):
	def __init__(self, export_prefix, filepath):
		super(RemoteCommand, self).__init__()
		self.name = 'export'
		self.export_prefix = export_prefix
		self.filepath = filepath

	def _run(self, virtual_machine, output_handler=None):
		return virtual_machine.export(self.export_prefix, self.filepath, output_handler=output_handler)


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
