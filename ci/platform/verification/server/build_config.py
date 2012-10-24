from build_command import NullBuildCommand, SimpleVagrantBuildCommand
from remote_linter import VagrantLintingCommand
from remote_test_runner import VagrantNoseCommand


class BuildConfig(object):
	def __init__(self, build_command, test_command):
		self.build_command = build_command
		self.test_command = test_command

	@classmethod
	def _get_default(cls):
		return BuildConfig(NullBuildCommand(), NullBuildCommand())

	@classmethod
	def _get_language_default(cls, language, path):
		if language == "python":
			return BuildConfig(VagrantLintingCommand(path), VagrantNoseCommand(path))
		else:
			return cls._get_default()

	@classmethod
	def from_config_tuple(cls, language, config):
		path = config.get("path") if config else None
		build_config = cls._get_language_default(language, path)
		if config:
			if "buildscript" in config:
				build_config.build_command = SimpleVagrantBuildCommand(config["buildscript"])
			if "testscript" in config:
				build_config.test_command = SimpleVagrantBuildCommand(config["testscript"])
		return build_config
