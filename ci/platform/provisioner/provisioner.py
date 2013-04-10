import os
import yaml

from database_parser import OmnibusDatabaseParser
from language_parser import LanguageParser
from package_parser import OmnibusPackageParser
from script_parser import ScriptParser
from run_step_parser import CompileStepParser, TestStepParser, PartitionStepParser
from setup_tools import InvalidConfigurationException, SetupCommand, SetupScript, RcUtils


class Provisioner(object):
	def __init__(self, packages=True, scripts=True, databases=True):
		self.setup_dispatcher = {
			'packages': self.parse_packages if packages else lambda *args: [],
			'scripts': self.parse_scripts if scripts else lambda *args: [],
			'databases': self.parse_databases if databases else lambda *args: []
		}
		self.ssh_dir = os.path.abspath(os.path.join(os.environ['HOME'], '.ssh'))
		self.keyfile = os.path.abspath(os.path.join(self.ssh_dir, 'id_rsa'))
		self.public_keyfile = os.path.abspath(os.path.join(self.ssh_dir, 'id_rsa.pub'))
		self.git_ssh = os.path.abspath(os.path.join(self.ssh_dir, 'id_rsa.koality'))

	def provision(self, private_key=None, config_path=None, source_path=None, global_install=False):
		config_path, source_path = self.resolve_paths(config_path, source_path)
		config = self.read_config(config_path)
		if private_key:
			self.set_private_key(private_key)
		steps = self.parse_config(config, source_path, global_install)
		self._provision(*steps)

	def resolve_paths(self, config_path=None, source_path=None):
		if not config_path:
			if not source_path:
				source_path = os.path.join(os.environ['HOME'], 'source')
			config_path = self._get_config_path(source_path)
		elif not source_path:
			source_path = os.path.dirname(config_path)
		return os.path.abspath(config_path), os.path.abspath(source_path)

	def read_config(self, config_path):
		try:
			with open(config_path) as config_file:
				config_text = config_file.read()
				return yaml.safe_load(config_text)
		except Exception as e:
			raise InvalidConfigurationException("Unable to parse configuration file: %s\n" % os.path.basename(config_path) +
				"Please verify that this is a valid YAML file using a tool such as http://yamllint.com/.",
				exception=e)

	def _get_config_path(self, source_path):
		possible_file_names = ['koality.yml', '.koality.yml']
		for file_name in possible_file_names:
			config_path = os.path.join(source_path, file_name)
			if os.access(config_path, os.F_OK):
				return config_path
		error_message = "Could not find a configuration file.\n"
		error_message += "Please place one of the following in the base of your repository: %s" % possible_file_names
		raise InvalidConfigurationException(error_message)

	def set_private_key(self, private_key):
		if not os.access(self.ssh_dir, os.F_OK):
			os.mkdir(self.ssh_dir)
		with open(self.keyfile, 'w') as keyfile:
			os.chmod(self.keyfile, 0600)
			keyfile.write(private_key)
		# Generate a proper public key
		SetupCommand.execute_script("ssh-keygen -y -f %s > %s" % (self.keyfile, self.public_keyfile))
		with open(self.git_ssh, 'w') as git_ssh:
			os.chmod(self.git_ssh, 0777)
			git_ssh.write('#!/bin/bash\n' +
				'ssh -oStrictHostKeyChecking=no -i %s $*' % self.keyfile)

	def parse_config(self, config, source_path, global_install=False):
		language_steps, setup_steps = self.parse_languages(config, global_install)
		language_steps.append(RcUtils.rc_append_command("export GIT_SSH=%s" % self.git_ssh, global_install=global_install, silent=True))
		setup_steps = [SetupCommand("pkill -9 -u rabbitmq beam; service rabbitmq-server start", silent=True, ignore_failure=True)] + setup_steps
		setup_steps += self.parse_setup(config, source_path)
		compile_steps = self.parse_compile(config, source_path)
		test_steps = self.parse_test(config, source_path)
		partition_commands = self.parse_partition(config, source_path)
		return (("Language configuration", SetupScript(*language_steps)),
			("Setup", SetupScript(*setup_steps)),
			("Compile configuration", compile_steps),
			("Test configuration", test_steps),
			("Test partitioners", partition_commands))

	def _provision(self, *steps):
		for action_name, step in steps:
			self._run_step(action_name, step)

	def _run_step(self, action_name, setup_step):
		if not setup_step:
			return
		steps = setup_step if isinstance(setup_step, list) else [setup_step]
		for step in steps:
			results = step.run()
			if results and results.returncode != 0:
				raise ProvisionFailedException("%s failed with return code %d" % (action_name, results.returncode))

	def parse_languages(self, config, global_install):
		if not 'languages' in config or len(config['languages']) == 0:
			raise InvalidConfigurationException("No languages specified")
		return LanguageParser(global_install).parse_languages(config['languages'])

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
			return CompileStepParser().parse_steps(config['compile'], source_path)

	def parse_test(self, config, source_path):
		if 'test' in config:
			return TestStepParser().parse_steps(config['test'], source_path)

	def parse_partition(self, config, source_path):
		if 'partition' in config:
			return PartitionStepParser().parse_steps(config['partition'], source_path)


class ProvisionFailedException(Exception):
	pass
