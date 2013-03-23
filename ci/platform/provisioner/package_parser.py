import collections
import os

from setup_tools import InvalidConfigurationException, SetupCommand


class PackageParser(object):
	def __init__(self, package_type):
		self.package_type = package_type

	def parse_packages(self, packages, source_path):
		package_steps = []
		for package in packages:
			new_package_steps = self.parse_package(package, source_path)
			if isinstance(new_package_steps, collections.Iterable):
				for package_step in new_package_steps:
					package_steps.append(package_step)
			else:
				package_steps.append(new_package_steps)
		return package_steps

	def parse_package(self, package, source_path, dict_commands=None):
		if isinstance(package, str):
			package_info = (package, None)
		elif isinstance(package, dict):
			if len(package.items()) > 1:
				raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
			package_info = package.items()[0]
		else:
			raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
		return self.to_install_command(source_path, *package_info)

	def to_install_command(self, source_path, name, value):
		package_string = self.to_package_string(name, value) if value else name
		return SetupCommand(self.to_install_string(package_string))

	def to_package_string(self, name, version):
		raise NotImplementedError()

	def to_install_string(self, package_string):
		raise NotImplementedError()


class OmnibusPackageParser(object):
	def __init__(self):
		self.package_dispatcher = {
			'system': SystemPackageParser(),
			'pip': PipPackageParser(),
			'gem': GemPackageParser(),
			'npm': NpmPackageParser()
		}

	def parse_packages(self, package_type, packages, source_path):
		try:
			parser = self.package_dispatcher[package_type]
		except KeyError:
			raise InvalidConfigurationException("Unknown package type: %s" % package_type)
		return parser.parse_packages(packages, source_path)


class SystemPackageParser(PackageParser):
	first_run = True

	def __init__(self):
		super(SystemPackageParser, self).__init__('system')

	def to_package_string(self, name, version):
		return "%s=%s" % (name, version)

	def to_install_string(self, package_string):
		return "apt-get install %s -y --force-yes" % package_string

	def parse_packages(self, packages, source_path):
		package_strings = []
		for package in packages:
			if isinstance(package, str):
				package_info = (package, None)
			elif isinstance(package, dict):
				if len(package.items()) > 1:
					raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
				package_info = package.items()[0]
			else:
				raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
			package_strings.append(self.to_package_string(*package_info) if package_info[1] else package_info[0])
		package_steps = [SetupCommand(self.to_install_string(" ".join(package_strings)))]
		if SystemPackageParser.first_run:
			SystemPackageParser.first_run = False
			package_steps = [SetupCommand("apt-get update -y", ignore_failure=True)] + package_steps
		return package_steps


class PipPackageParser(PackageParser):
	def __init__(self):
		super(PipPackageParser, self).__init__('pip')

	def to_install_command(self, source_path, name, value):
		if name == 'install requirements':
			if not value:
				value = "requirements.txt"
			return SetupCommand("pip install -r %s --use-mirrors" % os.path.join(source_path, value))
		return super(PipPackageParser, self).to_install_command(source_path, name, value)

	def to_package_string(self, name, version):
		return "%s==%s" % (name, version)

	def to_install_string(self, package_string):
		return "pip install %s --use-mirrors" % package_string


class GemPackageParser(PackageParser):
	def __init__(self):
		super(GemPackageParser, self).__init__('gem')

	def to_install_command(self, source_path, name, value):
		if name == 'bundle install':
			if value:
				return SetupCommand("cd %s" % source_path, "bundle install --gemfile %s" % os.path.join(source_path, value))
			return SetupCommand("cd %s" % source_path, "bundle install")
		return super(GemPackageParser, self).to_install_command(source_path, name, value)

	def to_package_string(self, name, version):
		return "%s -v %s" % (name, version)

	def to_install_string(self, package_string):
		return "gem install %s" % package_string


class NpmPackageParser(PackageParser):
	def __init__(self):
		super(NpmPackageParser, self).__init__('npm')

	def parse_package(self, package, source_path):
		return super(NpmPackageParser, self).parse_package(package, source_path, {
			'npm install': lambda package_info: SetupCommand("cd %s" % os.path.join(source_path, package_info[1]), "npm install")
		})

	def to_install_command(self, source_path, name, value):
		if name == 'npm install':
			return self._npm_install(source_path, value)
		return super(NpmPackageParser, self).to_install_command(source_path, name, value)

	def _npm_install(self, source_path, modules_path):
		link_command = self._link_node_modules(source_path, modules_path)
		if modules_path:
			install_command = SetupCommand("cd %s" % os.path.join(source_path, modules_path), "npm install")
		else:
			install_command = SetupCommand("npm install")
		return (link_command, install_command,)

	def _link_node_modules(self, source_path, modules_path):
		internal_modules_path = os.path.abspath(os.path.join(source_path, modules_path, "node_modules"))
		cached_modules_path = os.path.abspath(os.path.join(os.environ["HOME"], ".npm_cache", modules_path))
		return SetupCommand("[[ -d %s ]] || mkdir -p %s" % (cached_modules_path, cached_modules_path),
			"[[ -d %s ]] || ln -s %s %s" % (internal_modules_path, cached_modules_path, internal_modules_path),
			silent=True, ignore_failure=True)

	def to_package_string(self, name, version):
		return "%s@%s" % (name, version)

	def to_install_string(self, package_string):
		return "npm install -g %s" % package_string
