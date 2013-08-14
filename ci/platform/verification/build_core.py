import sys

import yaml

from model_server.build_consoles import ConsoleType
from util.log import Logged
from virtual_machine.remote_command import RemoteCheckoutCommand, RemotePatchCommand, RemoteExportCommand, RemoteProvisionCommand, RemoteTestCommand, InvalidConfigurationException


@Logged()
class VirtualMachineBuildCore(object):
	def __init__(self, virtual_machine, uri_translator=None):
		self.virtual_machine = virtual_machine
		self.uri_translator = uri_translator

	def setup(self):
		raise NotImplementedError()

	def teardown(self):
		raise NotImplementedError()

	def rebuild(self):
		raise NotImplementedError()

	def setup_build(self, repo_uri, repo_type, ref, private_key, patch_id=None, console_appender=None):
		self.setup_virtual_machine(private_key, console_appender)

	def _get_output_handler(self, console_appender, type, subtype=""):
		return console_appender(type, subtype) if console_appender else None

	def setup_virtual_machine(self, private_key, console_appender, setup_commands=[]):
		"""Provisions the contained virtual machine for analysis and test running"""
		provision_command = RemoteProvisionCommand(private_key)
		setup_commands = setup_commands + [provision_command]
		for setup_command in setup_commands:
			self.run_setup_command(setup_command, console_appender)

	def run_setup_command(self, setup_command, console_appender):
		results = setup_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Setup, setup_command.name))
		if results.returncode:
			raise VerificationException("Setup: %s" % setup_command.name)
		return results.output

	def run_compile_step(self, compile_commands, console_appender):
		for compile_command in compile_commands:
			self.run_compile_command(compile_command, console_appender)

	def run_compile_command(self, compile_command, console_appender):
		results = compile_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Compile, compile_command.name))
		if results.returncode:
			raise VerificationException("Compiling: %s" % compile_command.name)
		return results.output

	def run_test_command(self, test_command, console_appender):
		results = test_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Test, test_command.name))
		if results.returncode:
			raise VerificationException("Testing: %s" % test_command.name)
		return results.output

	def run_factory_command(self, factory_command, console_appender=None):
		output_handler = self._get_output_handler(console_appender, ConsoleType.TestFactory, factory_command.name)
		results = factory_command.run(self.virtual_machine, output_handler)
		if results.returncode:
			raise VerificationException("Factory: %s" % factory_command.name)

		def factory_failures(*exceptions):
			line_number = results.output.count('\n') + 3  # leave a blank line
			failure_lines = {}
			for e in exceptions:
				failure_message = '%s: %s' % (type(e).__name__, str(e))
				for line in failure_message.split('\n'):
					failure_lines[line_number] = line
					line_number += 1
				line_number += 1  # leave a blank line in between errors
			if output_handler:
				output_handler.append(failure_lines)
				output_handler.set_return_code(255)
			raise VerificationException("Factory: %s" % factory_command.name)

		try:
			test_sections = yaml.load(results.output)
		except yaml.YAMLError as e:
			factory_failures(e)

		if not isinstance(test_sections, list):
			test_sections = [test_sections]

		commands = []
		failures = []

		for test_section in test_sections:
			try:
				commands.append(RemoteTestCommand(test_section))
			except InvalidConfigurationException as e:
				failures.append(e)
		if failures:
			factory_failures(*failures)
		return commands

	def cache_repository(self, repo_uri, console_appender=None):
		repo_name = self.uri_translator.extract_repo_name(repo_uri)
		return self.virtual_machine.cache_repository(repo_name, console_appender)

	def export_path(self, export_prefix, filepath):
		export_command = RemoteExportCommand(export_prefix, filepath)
		return export_command.run(self.virtual_machine)


class VagrantBuildCore(VirtualMachineBuildCore):
	def __init__(self, vagrant, uri_translator=None):
		super(VagrantBuildCore, self).__init__(vagrant, uri_translator)

	def setup(self):
		self.virtual_machine.spawn()

	def teardown(self):
		self.virtual_machine.teardown()

	def rebuild(self):
		self.virtual.rebuild()


class CloudBuildCore(VirtualMachineBuildCore):
	def __init__(self, cloud_vm, uri_translator=None):
		super(CloudBuildCore, self).__init__(cloud_vm, uri_translator)

	def setup(self):
		max_attempts = 8
		for attempt in range(max_attempts):
			try:
				self.virtual_machine.wait_until_ready()
			except:
				exc_info = sys.exc_info()
				if attempt == max_attempts - 1:
					self.logger.error("Failed to set up virtual machine %s" % self.virtual_machine, exc_info=exc_info)
					raise exc_info
				self.logger.warn("Failed to set up virtual machine %s, trying again" % self.virtual_machine, exc_info=exc_info)
			else:
				break

	def teardown(self):
		self.virtual_machine.delete()

	def rebuild(self):
		self.virtual_machine.rebuild()

	def setup_build(self, repo_uri, repo_type, ref, private_key, patch_id=None, console_appender=None):
		self.setup_virtual_machine(repo_uri, repo_type, ref, private_key, patch_id, console_appender)

	def setup_virtual_machine(self, repo_uri, repo_type, ref, private_key, patch_id, console_appender):
		checkout_url = self.uri_translator.translate(repo_uri)
		repo_name = self.uri_translator.extract_repo_name(repo_uri)
		commands = [RemoteCheckoutCommand(repo_name, checkout_url, repo_type, ref)]
		if patch_id:
			commands.append(RemotePatchCommand(repo_name, checkout_url, repo_type, ref, patch_id))
		super(CloudBuildCore, self).setup_virtual_machine(private_key, console_appender, commands)


class VerificationException(Exception):
	"""Default exception to be thrown during verification failure.

	Contains a failed component name, and optionally a returncode and details
	"""
	def __init__(self, component, returncode=None, details=None):
		self.component = component
		self.returncode = returncode
		self.details = details

	def __str__(self):
		str_rep = "Failed verification (" + self.component + ")"
		if self.returncode:
			str_rep += " with return code: " + str(self.returncode)
		if self.details:
			str_rep += " Details: " + str(self.details)
		return str_rep
