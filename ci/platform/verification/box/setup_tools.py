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

	def to_shell_command(self):
		return "bash --login -c %s" % pipes.quote("\n".join(self.commands))

	def execute(self):
		with open("/tmp/setup-script", "w") as script_file:
			for command in self.commands:
				script_file.write("echo -e $ %s\n" % pipes.quote(command))
				script_file.write("%s\n" % command)
				script_file.write("r=$?\n")
				script_file.write("if [ $r -ne 0 ]; then echo \"command failed with return code $r\"; exit $r; fi")
		return StreamingExecutor.execute(shlex.split("bash /tmp/setup-script", output_handler=SimplePrinter()))


class SimplePrinter(object):
	def append(self, line_number, line):
		print "%s: %s" % (line_number, line)


class InvalidConfigurationException(Exception):
	pass
