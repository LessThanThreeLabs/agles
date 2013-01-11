import pipes
import shlex

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
	def execute_script(cls, script):
		return StreamingExecutor.execute(shlex.split("sudo -E bash --login -i -c %s" % pipes.quote(script)), output_handler=SimplePrinter())

	@classmethod
	def execute_script_file(cls, script_file):
		return StreamingExecutor.execute(shlex.split("sudo -E bash --login -i %s" % pipes.quote(script_file)), output_handler=SimplePrinter())

	def to_shell_command(self, fail_silently=False):
		script = ''
		for command in self.commands:
			script = script + "echo -e $ %s\n" % pipes.quote(command)
			script = script + "%s\n" % command
			script = script + self._check_return_code(fail_silently)
		return script

	def to_subshell_command(self):
		return "(%s)\n" % self.to_shell_command(True) + self._check_return_code()

	def _check_return_code(self, fail_silently=False):
		failure_command = ('' if fail_silently else "echo \"command failed with return code $r\";") + "exit $r"
		script = "r=$?\n"
		script = script + "if [ $r -ne 0 ]; then %s; fi\n" % failure_command
		return script


class SimplePrinter(object):
	def append(self, line_number, line):
		print "%s: %s" % (line_number, line)


class InvalidConfigurationException(Exception):
	pass
