from build_command import NullBuildCommand, SimpleVagrantBuildCommand


class BuildConfig(object):
	def __init__(self, build_command, test_command):
		self.build_command = build_command
		self.test_command = test_command

	@classmethod
	def _get_default(cls):
		return BuildConfig(NullBuildCommand(), NullBuildCommand())

	@classmethod
	def _get_language_default(cls, language, path):
		build_config = cls._get_default()
		if language == "python":
			build_config.test_command = SimpleVagrantBuildCommand("python", "nosetests", path)
		if language == "ruby":
			build_config.build_command = SimpleVagrantBuildCommand("ruby", "bundle install", path)
			build_config.test_command = SimpleVagrantBuildCommand("ruby", "rake", path)
		if language == "nodejs":
			build_config.test_command = SimpleVagrantBuildCommand("nodejs", "npm test", path)
		return build_config

	@classmethod
	def _construct_build_command(cls, language, command):
		if command is not None:
			return SimpleVagrantBuildCommand(language, command.rstrip().split("\n"))
		return NullBuildCommand()

	@classmethod
	def from_config_tuple(cls, language, config):
		path = config.get("path") if config else None
		build_config = cls._get_language_default(language, path)
		if config:
			if "buildscript" in config:
				build_config.build_command = cls._construct_build_command(language, config["buildscript"])
			if "testscript" in config:
				build_config.test_command = cls._construct_build_command(language, config["testscript"])
		return build_config
