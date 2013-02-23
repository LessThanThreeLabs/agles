import pipes
import shlex
import sys

from util.streaming_executor import StreamingExecutor


class SetupCommand(object):
	def __init__(self, commands):
		if isinstance(commands, str):
			self.commands = [commands]
		elif isinstance(commands, list):
			self.commands = commands
		else:
			raise InvalidConfigurationException("Invalid setup command: %s" % commands)

	def execute(self):
		self.execute_script(self.to_shell_command())

	@classmethod
	def execute_script(cls, script, env={}, login=True):
		command = "bash -c %s" % pipes.quote(script)
		return StreamingExecutor.execute(shlex.split(cls.wrap_command(command, login)), output_handler=SimplePrinter(), env=env)

	@classmethod
	def execute_script_file(cls, script_file, env={}, login=True):
		command = "bash %s" % script_file
		return StreamingExecutor.execute(shlex.split(cls.wrap_command(command, login)), output_handler=SimplePrinter(), env=env)

	@classmethod
	def wrap_command(cls, command, login):
		if login:
			return "bash --login -c %s" % pipes.quote("rvmsudo -E %s" % command)
		else:
			return "sudo -E %s" % command

	def to_shell_command(self):
		script = ''
		for command in self.commands:
			script = script + "echo -e $ %s\n" % pipes.quote(command)
			script = script + "%s\n" % command
			script = script + self._check_return_code()
		return script

	def to_subshell_command(self):
		return "(%s)\n" % self.to_shell_command() + self._check_return_code()

	def _check_return_code(self):
		return "_r=$?; if [ $_r -ne 0 ]; then exit $_r; fi\n"


class SimplePrinter(object):
	def __init__(self):
		self.last_line_number = 1
		self.last_column = 0

	def append(self, read_lines):
		for line_number, line in sorted(read_lines.items()):
			if line_number > self.last_line_number:
				self.last_line_number = line_number
				output = '\n' + line
			else:
				output = line[self.last_column:]
			self.last_column = len(line)
			sys.stdout.write(output)


class InvalidConfigurationException(Exception):
	pass
