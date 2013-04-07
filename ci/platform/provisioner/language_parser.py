import os
import pipes
import shlex
import subprocess

from setup_tools import SetupCommand, RcUtils, InvalidConfigurationException


class LanguageParser(object):
	def __init__(self, global_install=False):
		self.language_dispatcher = {
			'python': self.validate_python,
			'ruby': self.validate_ruby,
			'nodejs': self.validate_nodejs,
			'java': self.validate_jvm,
			'jvm': self.validate_jvm
		}
		self.global_install = global_install

	def parse_languages(self, language_config):
		rc_path = RcUtils.rc_path(self.global_install)
		source_command = "source %s" % rc_path
		language_steps = [SetupCommand("mkdir -p %s" % RcUtils.base_directory(self.global_install), silent=True),
			SetupCommand("echo \"# Automatically generated by Koality\" > %s" % rc_path, silent=True),  # Clear the koality rc file
			SetupCommand("grep -q \"%s\" ~/.bash_profile || echo \"%s\" >> ~/.bash_profile" % (source_command, source_command), silent=True)]
		setup_steps = []
		for language, version in language_config.items():
			try:
				new_language_steps, new_setup_steps = self.language_dispatcher[language](version)
			except KeyError:
				raise InvalidConfigurationException("Unsupported language: %s" % language)
			language_steps = language_steps + new_language_steps
			setup_steps = setup_steps + new_setup_steps
		return language_steps, setup_steps

	def validate_python(self, version):
		virtualenv_path = self._virtualenv_path(version)
		virtualenv_activate_path = self._virtualenv_activate_path(version)
		source_command = RcUtils.rc_append_command("source %s" % virtualenv_activate_path, self.global_install)

		if self.global_install:
			language_steps = [SetupCommand("virtualenv %s -p python%s" % (virtualenv_path, version)),
				SetupCommand("ln -s %s %s" % (os.path.join(virtualenv_path, 'bin', 'python'), os.path.join(RcUtils.base_directory(self.global_install), 'python'))),
				source_command]
		else:
			if not os.access(virtualenv_path, os.F_OK):
				raise InvalidConfigurationException("Python version %s not supported" % version)
			language_steps = [source_command]
		return language_steps, [SetupCommand("python --version")]

	def _virtualenv_path(self, version):
		if self.global_install:
			return os.path.join(RcUtils.base_directory(self.global_install), 'python%s' % version)
		return os.path.join(RcUtils.base_directory(self.global_install), 'virtualenvs', str(version))

	def _virtualenv_activate_path(self, version):
		return os.path.join(self._virtualenv_path(version), 'bin', 'activate')

	def validate_ruby(self, version):
		if self.global_install:
			language_steps = []
		else:
			installed_versions = subprocess.check_output(shlex.split(self._rvm_command("rvm list strings"))).split()
			version_found = any(map(lambda version_string: version_string.find(version) != -1, installed_versions))
			if version_found:
				language_steps = []
			else:
				print "Ruby version %s not pre-installed, will attempt to install" % version
				language_steps = [SetupCommand("rvm install %s" % version)]
			language_steps.append(RcUtils.rc_append_command("rvm use %s > /dev/null" % version, self.global_install))
			language_steps.append(RcUtils.rc_append_command("alias sudo=rvmsudo", self.global_install))
		return language_steps, [SetupCommand("ruby --version")]

	def _rvm_command(self, shell_command):
		return "bash --login -c %s" % pipes.quote(shell_command)

	def validate_nodejs(self, version):
		base_directory = RcUtils.base_directory(self.global_install)
		nvm_path = os.path.join(base_directory, 'nvm', 'nvm.sh')
		language_steps = [SetupCommand("source %s" % nvm_path, "nvm install %s" % version, "nvm use %s" % version, "npm update -g npm")]
		language_steps.append(RcUtils.rc_append_command("source %s > /dev/null" % nvm_path, self.global_install))
		language_steps.append(RcUtils.rc_append_command("nvm use %s > /dev/null" % version, self.global_install))
		if self.global_install:
			language_steps.append(SetupCommand("ln -s %s %s" % (os.path.join(base_directory, 'nvm', 'v' + version, 'bin', 'node'),
				os.path.join(base_directory, 'node'))))
			return language_steps, []
		return language_steps, [SetupCommand("node --version")]

	def _nvm_command(self, shell_command):
		return "bash -c %s" % pipes.quote(shell_command)

	def validate_jvm(self, version):
		version = str(version).lower()
		version_aliases = {
			'5': ['1.5', '1.5.0'],
			'6': ['1.6', '1.6.0'],
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
		language_steps = [RcUtils.rc_append_command("export JAVA_HOME=%s" % java_home, self.global_install),
			RcUtils.rc_append_command("export PATH=%s:$PATH" % java_path, self.global_install)]
		return language_steps, [SetupCommand("java -version")]
