from setup_tools import SetupCommand, InvalidConfigurationException


class ScriptParser(object):
	def parse_script(self, script_info):
		if isinstance(script_info, str):
			return SetupCommand(script_info)
		elif isinstance(script_info, dict):
			return self.parse_dict(script_info)
		else:
			raise InvalidConfigurationException("Unable to parse script: %s" % script_info)

	def parse_dict(self, script_info):
		if not 'script' in script_info:
			raise InvalidConfigurationException("Scripts must be a string or dictionary containing \"script\". Error at: %s" % script_info)
		directory = None
		for key, value in script_info.items():
			if key == 'script':
				if isinstance(script_info['script'], str):
					script = [script_info['script']]
				elif isinstance(script_info['script'], list):
					script = script_info['script']
			elif key == 'directory':
				directory = script_info['directory']
			else:
				raise InvalidConfigurationException("Invalid script modifier: (%s: %s)" % (key, value))
		commands = ["cd %s" % directory] if directory else []
		commands = commands + script
		return SetupCommand(commands)
