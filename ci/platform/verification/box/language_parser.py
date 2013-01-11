import os
import pipes
import re
import shlex
import subprocess

from setup_tools import SetupCommand, InvalidConfigurationException


class LanguageParser(object):
	def __init__(self):
		self.language_dispatcher = {
			'python': self.validate_python,
			'ruby': self.validate_ruby,
			'nodejs': self.validate_nodejs
		}

	def parse_languages(self, language_config):
		languages = {}
		setup_steps = []
		for language, version in language_config.items():
			try:
				languages[language], steps = self.language_dispatcher[language](version)
			except KeyError:
				raise InvalidConfigurationException("Unsupported language: %s" % language)
			setup_steps = setup_steps + steps
		return languages, setup_steps

	def validate_python(self, version):
		if not os.access(os.path.join(self._virtualenv_path(), str(version)), os.F_OK):
			raise InvalidConfigurationException("Python version %s not supported" % version)
		return version, [SetupCommand("echo \"source ~/virtualenvs/%s/bin/activate\" >> .bashrc")]

	def _virtualenv_path(self):
		return os.path.join(os.environ['HOME'], 'virtualenvs')

	def validate_ruby(self, version):
		installed_versions = subprocess.check_output(shlex.split(self._rvm_command("rvm list strings"))).split()
		version_found = any(map(lambda version_string: version_string.find(version) != -1, installed_versions))
		if version_found:
			setup_steps = []
		else:
			print "Ruby version %s not pre-installed, attempting to install" % version
			setup_steps = [SetupCommand("rvm install %s" % version)]
		setup_steps.append(SetupCommand("echo \"rvm use %s > /dev/null\" >> .bashrc" % version))
		return version, setup_steps

	def _rvm_command(self, shell_command):
		return "bash --login -c %s" % pipes.quote(shell_command)

	def validate_nodejs(self, version):
		strip_ansi = re.compile("\033\[[0-9;]+m")
		nvm_output = subprocess.check_output(shlex.split(self._nvm_command("source ~/nvm.sh > /dev/null; nvm ls %s" % version)))
		installed_version = strip_ansi.sub("", nvm_output).split()[0]
		setup_steps = [SetupCommand("echo \"source ~/nvm.sh > /dev/null\" >> .bashrc")]
		if installed_version == 'N/A':
			print "Nodejs version %s not pre-installed, attempting to install" % version
			setup_steps.append(SetupCommand("nvm install %s" % version))
		setup_steps.append(SetupCommand("echo \"nvm use %s > /dev/null\" >> .bashrc"))
		return version, setup_steps

	def _nvm_command(self, shell_command):
		return "bash --login -c %s" % pipes.quote(shell_command)
