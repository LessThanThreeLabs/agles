import pipes
import shlex

from util.streaming_executor import StreamingExecutor


class SetupCommand(object):
	def __init__(self, *commands, **kwargs):
		self.commands = commands
		self.silent = kwargs.pop('silent', False)
		self.ignore_failure = kwargs.pop('ignore_failures', False)

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

	@classmethod
	def to_setup_script(cls, commands):
		return cls._and(*map(lambda command: command.to_subshell_command(), commands))

	@classmethod
	def _and(cls, *commands):
		return ' &&\n'.join(commands)

	def to_shell_command(self):
		return self._and(*map(self._to_command, self.commands))

	def _to_command(self, command):
		if self.silent:
			return '(%s) > /dev/null' % command
		return self._and("echo -e $ %s" % pipes.quote(command), command)

	def to_subshell_command(self):
		return '(%s)' % self.to_shell_command()


class SimplePrinter(object):
	def append(self, line_number, line):
		print line


class InvalidConfigurationException(Exception):
	pass
