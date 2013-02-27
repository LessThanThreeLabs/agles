import os
import pipes
import shlex
import subprocess

from setup_tools import SetupCommand, InvalidConfigurationException


class LanguageParser(object):
	def __init__(self):
		self.language_dispatcher = {
			'python': self.validate_python,
			'ruby': self.validate_ruby,
			'nodejs': self.validate_nodejs,
			'java': self.validate_java,
			'jvm': self.validate_java
		}

	def parse_languages(self, language_config, global_install):
		language_steps = []
		setup_steps = []
		for language, version in language_config.items():
			try:
				new_language_steps, new_setup_steps = self.language_dispatcher[language](version, global_install)
			except KeyError:
				raise InvalidConfigurationException("Unsupported language: %s" % language)
			language_steps = language_steps + new_language_steps
			setup_steps = setup_steps + new_setup_steps
		return language_steps, setup_steps

	def validate_python(self, version, global_install):
		if global_install:
			return [], []
		if not os.access(os.path.join(self._virtualenv_path(), str(version)), os.F_OK):
			raise InvalidConfigurationException("Python version %s not supported" % version)
		language_steps = [SetupCommand("echo \"source ~/virtualenvs/%s/bin/activate\" >> ~/.bash_profile" % version)]
		return language_steps, [SetupCommand("python --version")]

	def _virtualenv_path(self):
		return os.path.join(os.environ['HOME'], 'virtualenvs')

	def validate_ruby(self, version, global_install):
		if global_install:
			return [], []
		installed_versions = subprocess.check_output(shlex.split(self._rvm_command("rvm list strings"))).split()
		version_found = any(map(lambda version_string: version_string.find(version) != -1, installed_versions))
		if version_found:
			language_steps = []
		else:
			print "Ruby version %s not pre-installed, attempting to install" % version
			language_steps = [SetupCommand("rvm install %s" % version)]
		language_steps.append(SetupCommand("echo \"rvm use %s > /dev/null\" >> ~/.bash_profile" % version))
		language_steps.append(SetupCommand("echo \"alias sudo=rvmsudo\" >> ~/.bash_profile"))
		return language_steps, [SetupCommand("ruby --version")]

	def _rvm_command(self, shell_command):
		return "bash --login -c %s" % pipes.quote(shell_command)

	def validate_nodejs(self, version, global_install):
		language_steps = [SetupCommand("source ~/nvm/nvm.sh", "nvm install %s" % version, "nvm use %s" % version, "npm install -g npm")]
		language_steps.append(SetupCommand("echo \"source ~/nvm/nvm.sh > /dev/null\" >> ~/.bash_profile"))
		language_steps.append(SetupCommand("echo \"nvm use %s > /dev/null\" >> ~/.bash_profile" % version))
		if global_install:
			return language_steps, []
		return language_steps, [SetupCommand("node --version")]

	def _nvm_command(self, shell_command):
		return "bash -c %s" % pipes.quote(shell_command)

	def validate_java(self, version, global_install):
		if global_install:
			return [], []
		version = str(version).lower()
		version_aliases = {
			'5': ['1.5', '1.5.0', '1.5.0.22', '1.5.0_22'],
			'6': ['1.6', '1.6.0', '1.6.0.24', '1.6.0_24'],
			'openjdk6': ['openjdk-6']
		}
		version_map = {
			'5': '/usr/lib/jvm/java-1.5.0-sun',
			'6': '/usr/lib/jvm/java-6-sun',
			'openjdk6': '/usr/lib/jvm/java-6-openjdk'
		}
		for version_name, aliases in version_aliases.items():
			for alias in aliases:
				version_map[alias] = version_map[version_name]
		try:
			java_home = version_map[version]
		except KeyError:
			raise InvalidConfigurationException("Java version %s not supported" % version)
		java_path = os.path.join(java_home, 'bin')
		language_steps = [SetupCommand("echo \"export JAVA_HOME=%s\" >> ~/.bash_profile" % java_home)]
		language_steps.append(SetupCommand("echo \"export PATH=%s:$PATH\" >> ~/.bash_profile" % java_path))
		return language_steps, [SetupCommand("java -version")]
