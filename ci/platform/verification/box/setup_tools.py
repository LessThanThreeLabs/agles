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
		script = ''
		for command in self.commands:
			script = script + "echo -e $ %s\n" % pipes.quote(command)
			script = script + "%s\n" % command
			script = script + "r=$?\n"
			script = script + "if [ $r -ne 0 ]; then echo \"command failed with return code $r\"; exit $r; fi\n"
		results = StreamingExecutor.execute(shlex.split("sudo -E bash --login -i -c %s" % pipes.quote(script)), output_handler=SimplePrinter())
		return results


class SimplePrinter(object):
	def append(self, line_number, line):
		print "%s: %s" % (line_number, line)


class InvalidConfigurationException(Exception):
	pass
