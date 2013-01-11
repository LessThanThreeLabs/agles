import os
import yaml

from database_parser import OmnibusDatabaseParser
from language_parser import LanguageParser
from package_parser import OmnibusPackageParser
from script_parser import ScriptParser
from setup_tools import InvalidConfigurationException, SetupCommand


class Provisioner(object):

	def __init__(self):
		self.setup_dispatcher = {
			'packages': self.parse_packages,
			'scripts': self.parse_scripts,
			'databases': self.parse_databases
		}

	def provision(self, config_path=None, source_path=None):
		if not config_path:
			if not source_path:
				source_path = os.path.join(os.environ['HOME'], 'source')
			config_path = os.path.join(source_path, 'koality.yml')
		elif not source_path:
			source_path = os.path.dirname(config_path)
		with open(config_path) as config_file:
			config = yaml.load(config_file.read())
		self.handle_config(config, source_path)

	def handle_config(self, config, source_path):
		languages, setup_steps = self.parse_languages(config)
		setup_steps = setup_steps + self.parse_setup(config, source_path)
		#compile_steps = self.parse_compile(config)
		#test_steps = self.parse_test(config)
		self._provision(languages, setup_steps)

	def _provision(self, languages, setup_steps):
		for language_info in languages.items():
			print "%s: %s" % language_info
		for step in setup_steps:
			results = step.execute()
			if results.returncode != 0:
				raise ProvisionFailedException("%s failed with return code %d" % (step.commands, results.returncode))

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
		return setup_steps + [SetupCommand("chown -R $USER:$USER $HOME")]

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


class ProvisionFailedException(Exception):
	pass

"""
sudo ln -s `which ruby` /usr/local/bin/ruby
"""
