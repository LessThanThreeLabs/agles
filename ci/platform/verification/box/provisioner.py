import os
import yaml

from database_parser import OmnibusDatabaseParser
from language_parser import LanguageParser
from package_parser import OmnibusPackageParser
from script_parser import ScriptParser
from run_step_parser import CompileStepParser, TestStepParser
from setup_tools import InvalidConfigurationException, SetupCommand


class Provisioner(object):

	def __init__(self):
		self.setup_dispatcher = {
			'packages': self.parse_packages,
			'scripts': self.parse_scripts,
			'databases': self.parse_databases
		}

	def provision(self, config_path=None, source_path=None):
		try:
			if not config_path:
				if not source_path:
					source_path = os.path.join(os.environ['HOME'], 'source')
				config_path = os.path.join(source_path, 'koality.yml')
			elif not source_path:
				source_path = os.path.dirname(config_path)
			source_path = os.path.abspath(source_path)
			config_path = os.path.abspath(config_path)
			with open(config_path) as config_file:
				config = yaml.load(config_file.read())
			self.handle_config(config, source_path)
		except Exception as e:
			print "%s: %s" % (type(e).__name__, e.message)

	def handle_config(self, config, source_path):
		language_steps, setup_steps = self.parse_languages(config)
		setup_steps = setup_steps + self.parse_setup(config, source_path)
		self.parse_compile(config, source_path)
		self.parse_test(config, source_path)
		self._provision(language_steps, setup_steps)

	def _provision(self, language_steps, setup_steps):
		self.run_setup_steps(language_steps, action_name='Language configuration')
		self.run_setup_steps(setup_steps)

	def run_setup_steps(self, setup_steps, action_name='Setup'):
		script = ''.join(map(lambda step: step.to_subshell_command(), setup_steps))
		script_path = '/tmp/setup-script'
		with open(script_path, 'w') as setup_script:
			setup_script.write(script)
		results = SetupCommand.execute_script_file(script_path, env={'GIT_SSH': 'ssh -oStrictHostKeyChecking=no'})
		os.remove(script_path)
		if results.returncode != 0:
			raise ProvisionFailedException("%s failed with return code %d" % (action_name, results.returncode))

	def parse_languages(self, config):
		if not 'languages' in config or len(config['languages']) == 0:
			raise InvalidConfigurationException("No languages specified")
		return LanguageParser().parse_languages(config['languages'])

	def parse_setup(self, config, source_path):
		setup_steps = []
		if not 'setup' in config:
			return setup_steps
		for step_config in config['setup']:
			step_type, steps = step_config.items()[0]
			try:
				setup_steps = setup_steps + self.setup_dispatcher[step_type](steps, source_path)
			except KeyError:
				raise InvalidConfigurationException("Unknown setup type: %s" % step_type)
		return setup_steps + [SetupCommand("chown -R lt3:lt3 /home/lt3")]

	def parse_packages(self, package_config, source_path):
		package_steps = []
		for package_info in package_config:
			package_type, packages = package_info.items()[0]
			package_steps = package_steps + OmnibusPackageParser().parse_packages(package_type, packages, source_path)
		return package_steps

	def parse_scripts(self, script_config, source_path):
		script_steps = []
		for script_info in script_config:
			script_steps.append(ScriptParser().parse_script(script_info, source_path))
		return script_steps

	def parse_databases(self, database_config, source_path):
		database_steps = []
		for database_info in database_config:
			database_type, databases = database_info.items()[0]
			database_steps = database_steps + OmnibusDatabaseParser().parse_databases(database_type, databases)
		return database_steps

	def parse_compile(self, config, source_path):
		if 'compile' in config:
			CompileStepParser().parse(config['compile'])

	def parse_test(self, config, source_path):
		if 'test' in config:
			TestStepParser().parse(config['test'])


class ProvisionFailedException(Exception):
	pass
