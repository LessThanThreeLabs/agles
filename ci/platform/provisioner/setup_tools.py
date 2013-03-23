import os
import pipes
import shlex
import sys

from util.streaming_executor import StreamingExecutor


class SetupCommand(object):
	def __init__(self, *commands, **kwargs):
		self.commands = commands
		self.silent = kwargs.pop('silent', False)
		self.ignore_failure = kwargs.pop('ignore_failure', False)

	def execute(self):
		self.execute_script(self.to_shell_command())

	@classmethod
	def execute_script(cls, script, env={}, login=True):
		command = "bash -c %s" % pipes.quote(script)
		return StreamingExecutor().execute(shlex.split(cls.wrap_command(command, login)), output_handler=SimplePrinter(), env=env)

	@classmethod
	def execute_script_file(cls, script_file, env={}, login=True):
		command = "bash %s" % script_file
		return StreamingExecutor().execute(shlex.split(cls.wrap_command(command, login)), output_handler=SimplePrinter(), env=env)

	@classmethod
	def wrap_command(cls, command, login):
		if login:
			return "bash --login -c %s" % pipes.quote("rvmsudo -E %s" % command)
		else:
			return "sudo -E %s" % command

	def _and(cls, *commands):
		return ' &&\n'.join(commands)

	def _or(cls, *commands):
		return ' ||\n'.join(commands)

	def to_shell_command(self):
		shell_command = self._and(*map(self._to_command, self.commands))
		if self.ignore_failure:
			return self._or(shell_command, "true")
		return shell_command

	def _to_command(self, command):
		if self.silent:
			return '(%s) > /dev/null' % command
		return self._and("echo -e $ %s" % pipes.quote(command), command)

	def to_subshell_command(self):
		return '(%s)' % self.to_shell_command()

	def __repr__(self):
		return "SetupCommand(%s)" % ", ".join(
			[repr(command) for command in self.commands] +
			["%s=%s" % (attr, repr(getattr(self, attr))) for attr in
				['silent', 'ignore_failure']])


class SetupScript(object):
	def __init__(self, *setup_steps):
		self.setup_steps = setup_steps

	def run(self):
		script_path = '/tmp/setup-script'
		with open(script_path, 'w') as setup_script:
			setup_script.write(self.get_script_contents())
		results = SetupCommand.execute_script_file(script_path)
		os.remove(script_path)
		return results

	def _and(self, *commands):
		return ' &&\n'.join(commands)

	def get_script_contents(self):
		return self._and(*map(lambda step: step.to_subshell_command(), self.setup_steps))

	def __repr__(self):
		return "SetupScript(%s)" % ", ".join([repr(step) for step in self.setup_steps])


class RcUtils(object):
	@classmethod
	def rc_append_command(cls, contents, global_install=False, silent=False):
		return SetupCommand("echo \"%s\" >> %s" % (contents, cls.rc_path(global_install)), silent=silent)

	@classmethod
	def rc_path(cls, global_install=False):
		return os.path.join(cls.base_directory(global_install), '.koalityrc')

	@classmethod
	def base_directory(cls, global_install=False):
		return os.path.join('/', 'etc', 'koality') if global_install else os.environ['HOME']


class SimplePrinter(object):
	def __init__(self):
		self.last_line_number = 1
		self.last_column = 0

	def append(self, read_lines):
		output = ""
		for line_number, line in sorted(read_lines.items()):
			if line_number > self.last_line_number:
				self.last_line_number = line_number
				output += '\n' + line
			else:
				output += line[self.last_column:]
		self.last_column = len(line)
		sys.stdout.write(output)

	def close(self):
		sys.stdout.write('\n')


class InvalidConfigurationException(Exception):
	def __init__(self, *args, **kwargs):
		self.args = args
		self.exception = kwargs.get('exception')

	def _indent(self, string):
		return "\n".join(map(lambda s: "\t" + s, string.split("\n")))

	def __repr__(self):
		return str(self)

	def __str__(self):
		return super(InvalidConfigurationException, self).__str__() + "\nInternal Error:\n%s" % self._indent(str(self.exception))
