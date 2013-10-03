import sys

import yaml
import model_server

from model_server.build_consoles import ConsoleType
from util.log import Logged
from virtual_machine.remote_command import RemoteTestCommand, RemoteExportCommand, InvalidConfigurationException


@Logged()
class VirtualMachineBuildCore(object):
	def __init__(self, virtual_machine, uri_translator):
		self.virtual_machine = virtual_machine
		self.uri_translator = uri_translator

	def setup(self):
		raise NotImplementedError()

	def teardown(self):
		raise NotImplementedError()

	def rebuild(self):
		raise NotImplementedError()

	def _get_output_handler(self, console_appender, type, subtype=""):
		return console_appender(type, subtype) if console_appender else None

	def run_setup_step(self, setup_commands, console_appender=None):
		"""Provisions the contained virtual machine for analysis and test running"""
		for setup_command in setup_commands:
			self.run_setup_command(setup_command, console_appender)

	def run_setup_command(self, setup_command, console_appender):
		results = setup_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Setup, setup_command.name))
		if results.returncode:
			raise VerificationException("Setup: %s" % setup_command.name)
		return results.output

	def run_compile_step(self, compile_commands, console_appender=None):
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

	def upload_xunit(self, build_id, test_command):
		xunit_contents = test_command.get_xunit_contents()
		if xunit_contents:
			with model_server.rpc_connect("build_consoles", "update") as client:
				client.store_xunit_contents(build_id, ConsoleType.Test, test_command.name, xunit_contents)

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

		if test_sections is None:
			if output_handler:
				output_handler.append({1: 'No test sections generated'})
			return []

		if not isinstance(test_sections, list):
			test_sections = [test_sections]

		commands = []
		failures = []

		for test_section in test_sections:
			try:
				commands.append(RemoteTestCommand(factory_command.repo_name, test_section))
			except InvalidConfigurationException as e:
				failures.append(e)
		if failures:
			factory_failures(*failures)
		return commands

	def cache_repository(self, repo_uri, console_appender=None):
		repo_name = self.uri_translator.extract_repo_name(repo_uri)
		return self.virtual_machine.cache_repository(repo_name, console_appender)

	def export_files(self, repo_name, export_prefix, file_paths, console_appender=None):
		if not file_paths:
			return []

		export_command = RemoteExportCommand(repo_name, export_prefix, file_paths)
		output_handler = self._get_output_handler(console_appender, ConsoleType.Export, export_command.name)
		results = export_command.run(self.virtual_machine, output_handler)
		export_uris = []
		if results.returncode != 0 and output_handler is not None:
			output_dict = {pair[0] + 1: pair[1] for pair in enumerate(results.output.split('\n'))}
			output_handler.append(output_dict)
		else:
			try:
				export_info = yaml.safe_load(results.output)
				export_uris = export_info['uris']
				export_errors = export_info['errors']
				if output_handler is not None:
					if export_uris:
						output_dict = {1: '%d files exported successfully.' % len(export_uris)}
					else:
						output_dict = {1: 'No files exported.'}
					if export_errors:
						output_dict[2] = ''
						for index, error in enumerate(export_errors):
							output_dict[index + 3] = error
					output_handler.append(output_dict)
			except:
				self.logger.exception('Failed to parse export output')

		def uri_to_metadata(export_uri):
			uri_suffix = export_uri.partition(export_prefix)[2]
			path = uri_suffix[1:]
			return {'uri': export_uri, 'path': path}

		return map(uri_to_metadata, export_uris)


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
	def __init__(self, cloud_vm, uri_translator):
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
