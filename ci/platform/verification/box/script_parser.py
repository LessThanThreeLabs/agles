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
		directory = source_path
		for key, value in script_info.items():
			if key == 'script':
				if isinstance(script_info['script'], str):
					script = [script_info['script']]
				elif isinstance(script_info['script'], list):
					script = script_info['script']
			elif key == 'directory':
				directory = os.path.join(source_path, script_info['directory'])
			else:
				raise InvalidConfigurationException("Invalid script modifier: (%s: %s)" % (key, value))
		return self.script_command(script, directory)

	def script_command(self, commands, directory):
		return SetupCommand(["cd %s" % directory] + commands)
