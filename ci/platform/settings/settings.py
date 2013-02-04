import inspect
import os
import yaml


class Settings(object):
	SETTINGS_DIRECTORIES = [os.path.join(os.environ['HOME'], 'koality')]
	SETTINGS_FILE_EXTENSIONS = ['yml']
	SETTINGS_EXTENSION_TO_HANDLER = {'yml': yaml.safe_load}
	_is_initialized = False

	@classmethod
	def initialize(cls):
		if not cls._is_initialized:
			cls.reinitialize()
			cls._is_initialized = True

	@classmethod
	def reinitialize(cls):
		cls()

	def __init__(self, **kwargs):
		self.filename = os.path.basename(inspect.getfile(inspect.currentframe().f_back))
		self.settings_dict = {}
		self._init_from_files()
		self.add_values(**kwargs)

	def _init_from_files(self):
		for settings_directory in self.SETTINGS_DIRECTORIES:
			for settings_dict in self._get_settings_files(settings_directory):
				for name, value in settings_dict.items():
					if name not in self.settings_dict:
						self.settings_dict[name] = value

	def _get_settings_files(self, settings_directory):
		for extension in self.SETTINGS_FILE_EXTENSIONS:
			settings_filename = os.path.join(settings_directory, self.filename[:self.filename.rfind('.') + 1] + extension)
			if os.access(settings_filename, os.F_OK):
				settings = self._parse_settings_file(settings_filename, extension)
				if settings:
					yield settings

	def _parse_settings_file(self, settings_filename, extension):
		with open(settings_filename) as settings_file:
			return self.SETTINGS_EXTENSION_TO_HANDLER[extension](settings_file.read())

	def add_values(self, **kwargs):
		for name, default_value in kwargs.items():
			self._value(name, default_value)

	def _value(self, name, default_value):
		value = self._load_value(name, default_value)
		setattr(type(self), name, value)

	def _load_value(self, name, default_value):
		return self.settings_dict.get(name, default_value)
