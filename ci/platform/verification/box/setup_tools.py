import pipes
import shlex
import subprocess


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
		with open("/tmp/setup-script") as script_file:
			for command in self.commands:
				script_file.write("echo -e $ %s" % pipes.quote(command))
				script_file.write(command)
				script_file.write("r=$?")
				script_file.write("if [ $r -ne 0 ]; then echo \"command failed with return code $r\"; exit $r; fi")
		print subprocess.check_output(shlex.split("bash /tmp/setup-script"))


class InvalidConfigurationException(Exception):
	pass
