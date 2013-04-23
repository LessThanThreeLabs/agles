import os
import shutil
import subprocess

import yaml

from git import Repo

from model_server.build_consoles import ConsoleType
from util.log import Logged
from virtual_machine.remote_command import RemoteCheckoutCommand, RemoteExportCommand, RemoteProvisionCommand
from verification_config import VerificationConfig


@Logged()
class BuildCore(object):
	"""Component that contains setup and cleanup functionality for
	steps in box setup related to building."""

	# TODO (bbland/jchu): This class has a fundamental flaw.
	# It copies the head to /tmp/source, but if 2 of these
	# are running at the same time, this is a race condition.
	# For every run, you should have a unique source_dir
	def __init__(self, uri_translator=None):
		self.uri_translator = uri_translator
		self.source_dir = os.path.join("/tmp", "source")

	def setup_build(self, repo_uri, ref, console_appender=None):
		self._checkout_ref(repo_uri, ref)
		verification_config = self._get_verification_configuration_from_file()
		return verification_config

	def _cleanup_source_dir(self):
		if os.access(self.source_dir, os.F_OK):
			shutil.rmtree(self.source_dir)

	def _checkout_ref(self, repo_uri, ref):
		self._cleanup_source_dir()
		if self.uri_translator:
			checkout_url = self.uri_translator.translate(repo_uri)
			host_url = checkout_url[:checkout_url.find(":")]
			# Add repostore to authorized keys for the following git command
			subprocess.call(["ssh", "-q", "-oStrictHostKeyChecking=no", host_url, "true"])
		else:
			checkout_url = repo_uri
		repo = Repo.init(self.source_dir)
		repo.git.fetch(checkout_url, ref, "-n", depth=1)
		repo.git.checkout("FETCH_HEAD")

	def _get_verification_configuration_from_file(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying"""
		config_path = self._get_config_path()
		if config_path:
			with open(config_path) as config_file:
				try:
					config = yaml.safe_load(config_file.read())
				except:
					config = dict()
		else:
			config = dict()
		return self._get_verification_configuration(config)

	def _get_config_path(self):
		possible_file_names = ['koality.yml', '.koality.yml']
		for file_name in possible_file_names:
			config_path = os.path.join(self.source_dir, file_name)
			if os.access(config_path, os.F_OK):
				return config_path

	def _get_verification_configuration(self, config_dict):
		try:
			return VerificationConfig(config_dict.get("compile", {}), config_dict.get("test", {}))
		except:
			self.logger.critical("Unexpected exception while getting verification configuration", exc_info=True)
			return VerificationConfig({}, {})


class LightWeightBuildCore(BuildCore):
	def setup_build(self, repo_uri, ref, console_appender=None):
		if self.uri_translator:
			checkout_url = self.uri_translator.translate(repo_uri)
			host_url = checkout_url[:checkout_url.find(":")]
			repo_path = checkout_url[checkout_url.find(":") + 1:]
			show_command = lambda file_name: ["ssh", "-q", "-oStrictHostKeyChecking=no", "%s" % host_url, "git-show", repo_path, "%s:%s" % (ref, file_name)]
		else:
			show_command = lambda file_name: ["bash", "-c", "cd %s && git show %s:%s" % (repo_uri, ref, file_name)]
		return self._get_verification_configuration(self._show_config(show_command))

	def _show_config(self, show_command):
		for file_name in ['koality.yml', '.koality.yml']:
			try:
				return yaml.safe_load(subprocess.check_output(show_command(file_name)))
			except:
				pass
		return {}


class VirtualMachineBuildCore(BuildCore):
	def __init__(self, virtual_machine, uri_translator=None):
		super(VirtualMachineBuildCore, self).__init__(uri_translator)
		self.virtual_machine = virtual_machine
		self.source_dir = os.path.join(virtual_machine.vm_directory, "source")

	def setup(self):
		raise NotImplementedError()

	def teardown(self):
		raise NotImplementedError()

	def setup_build(self, repo_uri, ref, private_key, console_appender=None):
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
		results = factory_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.TestFactory, factory_command.name))
		if results.returncode:
			raise VerificationException("Factory: %s:" % factory_command.name)
		return results.output

	def cache_repository(self, repo_uri, console_appender=None):
		repo_name = self.uri_translator.extract_repo_name(repo_uri)
		return self.virtual_machine.cache_repository(repo_name, console_appender)

	def export_path(self, export_prefix, filepath):
		export_command = RemoteExportCommand(export_prefix, filepath)
		return export_command.run(self.virtual_machine).output


class VagrantBuildCore(VirtualMachineBuildCore):
	def __init__(self, vagrant, uri_translator=None):
		super(VagrantBuildCore, self).__init__(vagrant, uri_translator)

	def setup(self):
		self.virtual_machine.spawn()

	def teardown(self):
		self.virtual_machine.teardown()


class CloudBuildCore(VirtualMachineBuildCore):
	def __init__(self, cloud_vm, uri_translator):
		super(CloudBuildCore, self).__init__(cloud_vm, uri_translator)

	def setup(self):
		while True:
			try:
				self.virtual_machine.wait_until_ready()
			except:
				self.logger.warn("Failed to set up virtual machine (%s, %s), trying again" % (self.virtual_machine.vm_directory, self.virtual_machine.instance.id), exc_info=True)
			else:
				break

	def teardown(self):
		self.virtual_machine.delete()

	def setup_build(self, repo_uri, ref, private_key, console_appender=None):
		self.setup_virtual_machine(repo_uri, ref, private_key, console_appender)

	def setup_virtual_machine(self, repo_uri, ref, private_key, console_appender):
		checkout_url = self.uri_translator.translate(repo_uri)
		repo_name = self.uri_translator.extract_repo_name(repo_uri)
		checkout_command = RemoteCheckoutCommand(repo_name, checkout_url, ref)
		super(CloudBuildCore, self).setup_virtual_machine(private_key, console_appender, [checkout_command])


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
