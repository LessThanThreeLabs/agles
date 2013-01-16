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
			'nodejs': self.validate_nodejs
		}

	def parse_languages(self, language_config):
		language_steps = []
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
		if not os.access(os.path.join(self._virtualenv_path(), str(version)), os.F_OK):
			raise InvalidConfigurationException("Python version %s not supported" % version)
		return [SetupCommand("echo \"source ~/virtualenvs/%s/bin/activate\" >> ~/.bash_profile" % version)], [SetupCommand("python --version")]

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
		setup_steps.append(SetupCommand("echo \"rvm use %s > /dev/null\" >> ~/.bash_profile" % version))
		setup_steps.append(SetupCommand("echo \"alias sudo=rvmsudo\" >> ~/.bash_profile"))
		return setup_steps, [SetupCommand("ruby --version")]

	def _rvm_command(self, shell_command):
		return "bash --login -c %s" % pipes.quote(shell_command)

	def validate_nodejs(self, version):
		setup_steps = [SetupCommand(["source ~/nvm/nvm.sh", "nvm install %s" % version, "npm install -g npm"])]
		setup_steps.append(SetupCommand("echo \"source ~/nvm/nvm.sh > /dev/null\" >> ~/.bash_profile"))
		setup_steps.append(SetupCommand("echo \"nvm use %s > /dev/null\" >> ~/.bash_profile" % version))
		return setup_steps, [SetupCommand("node --version")]

	def _nvm_command(self, shell_command):
		return "bash -c %s" % pipes.quote(shell_command)
