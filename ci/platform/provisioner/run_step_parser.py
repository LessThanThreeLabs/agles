import os
import pipes

from setup_tools import InvalidConfigurationException


class RunStepParser(object):
	def __init__(self, step_type):
		self.step_type = step_type

	def parse_steps(self, steps, source_path):
		return [RunStepFileBuilder(source_path, self.step_type, *self.parse_step(step)) for step in steps]

	def parse_step(self, step):
		path = '.'
		timeout = 600
		if isinstance(step, str):
			name = step
			commands = [step]
		elif isinstance(step, dict):
			if len(step.items()) > 1:
				raise InvalidConfigurationException("Could not parse %s step: %s" % (self.step_type, step))
			name = step.keys()[0]
			path, commands, timeout = self.parse_step_info(step.values()[0])
			if not commands:
				commands = [name]
		else:
			raise InvalidConfigurationException("Could not parse %s step: %s" % (self.step_type, step))
		return name, path, commands, timeout

	def parse_step_info(self, step_info):
		path = '.'
		commands = None
		timeout = 600
		if isinstance(step_info, str):
			commands = [step_info]
		elif isinstance(step_info, dict):
			for key, value in step_info.items():
				if key == 'script':
					commands = self.parse_script(value)
				elif key == 'path':
					path = value
				elif key == 'timeout':
					timeout = value
				else:
					raise InvalidConfigurationException("Invalid %s option: %s" % (self.step_type, key))
		return path, commands, timeout

	def parse_script(self, script):
		if isinstance(script, str):
			return [script]
		elif isinstance(script, list):
			return script
		else:
			raise InvalidConfigurationException("Could not parse %s script: %s" % (self.step_type, script))


class CompileStepParser(RunStepParser):
	def __init__(self):
		super(CompileStepParser, self).__init__('compile')


class TestStepParser(RunStepParser):
	def __init__(self):
		super(TestStepParser, self).__init__('test')


class PartitionStepParser(RunStepParser):
	def __init__(self):
		super(PartitionStepParser, self).__init__('partition')


class RunStepFileBuilder(object):
	def __init__(self, source_path, step_type, step_name, step_path, commands, timeout):
		self.source_path = source_path
		self.step_type = step_type
		self.step_name = step_name
		self.step_path = step_path
		self.commands = commands
		self.timeout = timeout

	def run(self):
		full_command = "&&\n".join(map(self._advertised_command, self.commands))
		script = "#!/bin/bash\n"
		script = script + "%s\n" % self._advertised_command("cd %s" % os.path.abspath(os.path.join(self.source_path, self.step_path)))
		script = script + "timeout -s INT -k 3 %d bash --login -c %s\n" % (self.timeout, pipes.quote(full_command))
		script = script + "_r=$?\n"
		script = script + "if [ $_r -eq 124 ]; then sleep 2; echo; echo %s timed out after %s seconds;\n" % (self.step_name, self.timeout)
		script = script + "elif [ $_r -ne 0 ]; then echo; echo %s failed with return code $_r; fi\n" % self.step_name
		script = script + "exit $_r"
		if not os.access(os.path.join(os.environ['HOME'], 'scripts', self.step_type), os.F_OK):
			os.makedirs(os.path.join(os.environ['HOME'], 'scripts', self.step_type))
		with open(os.path.join(os.environ['HOME'], 'scripts', self.step_type, self.step_name), 'w') as step_file:
			step_file.write(script)

	def _advertised_command(self, command):
		return "echo -e $ %s &&\n%s" % (pipes.quote(command), command)

	def __repr__(self):
		return "RunStepFileBuilder(%s)" % ", ".join(["%s=%s" % (attr, repr(getattr(self, attr))) for attr in
			['source_path', 'step_type', 'step_name', 'step_path', 'commands', 'timeout']])
