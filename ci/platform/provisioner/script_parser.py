import os

from setup_tools import SetupCommand, InvalidConfigurationException


class ScriptParser(object):
	def parse_script(self, script_info, source_path):
		if isinstance(script_info, str):
			return self.script_command(script_info, source_path)
		elif isinstance(script_info, dict):
			return self.parse_dict(script_info, source_path)
		else:
			raise InvalidConfigurationException("Unable to parse script: %s" % script_info)

	def parse_dict(self, script_info, source_path):
		if not 'script' in script_info:
			raise InvalidConfigurationException("Scripts must be a string or dictionary containing \"script\". Error at: %s" % script_info)
		directory = None
		for key, value in script_info.items():
			if key == 'script':
				if isinstance(value, str):
					script = value
				elif isinstance(value, list):
					script = "\n".join(value)
			elif key in ['path', 'directory']:
				if directory:
					raise InvalidConfigurationException("Script must contain at most one of the modifiers [\"path\", \"directory\"]")
				directory = os.path.join(source_path, value)
			else:
				raise InvalidConfigurationException("Invalid script modifier: (%s: %s)" % (key, value))
		return self.script_command(script, directory if directory else source_path)

	def script_command(self, command, directory):
		return SetupCommand("cd %s" % directory, command)
