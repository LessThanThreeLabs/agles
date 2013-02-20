import os

from setup_tools import InvalidConfigurationException, SetupCommand


class PackageParser(object):
	def __init__(self, package_type):
		self.package_type = package_type

	def parse_packages(self, packages, source_path):
		package_steps = []
		for package in packages:
			package_steps.append(self.parse_package(package, source_path))
		return package_steps

	def parse_package(self, package, source_path):
		if isinstance(package, str):
			package_string = package
		elif isinstance(package, dict):
			if len(package.items()) > 1:
				raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
			package_string = self.to_package_string(*package.items()[0])
		else:
			raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
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
		package_steps = super(SystemPackageParser, self).parse_packages(packages, source_path)
		if SystemPackageParser.first_run:
			SystemPackageParser.first_run = False
			package_steps = [SetupCommand("apt-get update -y")] + package_steps
		return package_steps


class PipPackageParser(PackageParser):
	def __init__(self):
		super(PipPackageParser, self).__init__('pip')

	def to_package_string(self, name, version):
		return "%s==%s" % (name, version)

	def to_install_string(self, package_string):
		return "pip install %s --upgrade" % package_string


class GemPackageParser(PackageParser):
	def __init__(self):
		super(GemPackageParser, self).__init__('gem')

	def to_package_string(self, name, version):
		return "%s -v %s" % (name, version)

	def to_install_string(self, package_string):
		return "gem install %s" % package_string


class NpmPackageParser(PackageParser):
	def __init__(self):
		super(NpmPackageParser, self).__init__('npm')

	def parse_package(self, package, source_path):
		if isinstance(package, str):
			package_string = package
		elif isinstance(package, dict):
			if len(package.items()) > 1:
				raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
			package_info = package.items()[0]
			if package_info[0] == 'directory':
				return SetupCommand("cd %s" % os.path.join(source_path, package_info[1]), "npm install")
			package_string = self.to_package_string(*package_info)
		else:
			raise InvalidConfigurationException("Could not parse %s package: %s" % (self.package_type, package))
		return SetupCommand(self.to_install_string(package_string))

	def to_package_string(self, name, version):
		return "%s@%s" % (name, version)

	def to_install_string(self, package_string):
		return "npm install -g %s" % package_string
