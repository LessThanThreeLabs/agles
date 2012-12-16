import os
import shutil

import yaml

from git import Git, Repo

from model_server.build_outputs import ConsoleType
from virtual_machine.remote_command import SimpleRemoteProvisionCommand
from verification_config import VerificationConfig
from verification_result import VerificationResult


class BuildCore(object):
	def __init__(self, uri_translator=None):
		self.uri_translator = uri_translator
		self.source_dir = os.path.join("/tmp", "source")

	def setup_build(self, repo_uri, refs, console_appender=None):
		self._checkout_refs(repo_uri, refs)
		verification_config = self._get_verification_configuration()
		return verification_config

	def _checkout_refs(self, repo_uri, refs):
		if os.access(self.source_dir, os.F_OK):
			shutil.rmtree(self.source_dir)
		checkout_url = self.uri_translator.translate(repo_uri) if self.uri_translator else repo_uri
		Git().clone(checkout_url, self.source_dir)
		repo = Repo(self.source_dir)
		ref = refs[0]
		repo.git.fetch("origin", ref)
		repo.git.checkout("FETCH_HEAD")
		for ref in refs[1:]:
			repo.git.fetch("origin", ref)
			repo.git.merge("FETCH_HEAD")

	def _get_verification_configuration(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying"""
		config_path = os.path.join(self.source_dir, "koality.yml")
		if os.access(config_path, os.F_OK):
			with open(config_path) as config_file:
				config = yaml.load(config_file.read())
		else:
			config = dict()
		verification_config = VerificationConfig(config.get("compile"), config.get("test"))
		return verification_config


class VirtualMachineBuildCore(BuildCore):
	def __init__(self, virtual_machine, uri_translator=None):
		super(VirtualMachineBuildCore, self).__init__(uri_translator)
		self.virtual_machine = virtual_machine

	def setup(self):
		raise NotImplementedError()

	def teardown(self):
		raise NotImplementedError()

	def rollback_virtual_machine(self):
		raise NotImplementedError()

	def setup_build(self, repo_uri, refs, console_appender=None):
		verification_config = super(VirtualMachineBuildCore, self).setup_build(repo_uri, refs)
		self.setup_virtual_machine(console_appender)
		return verification_config

	def _get_output_handler(self, console_appender, type, subtype=""):
		return console_appender(type, subtype) if console_appender else None

	def declare_commands(self, console_appender, console_type, commands):
		command_names = [command.name for command in commands]
		output_handler = self._get_output_handler(console_appender, console_type)
		if output_handler:
			output_handler.declare_commands(command_names)

	def setup_virtual_machine(self, console_appender):
		"""Provisions the contained virtual machine for analysis and test running"""
		setup_command = SimpleRemoteProvisionCommand("verification_box_run")
		self.declare_commands(console_appender, ConsoleType.Setup, [setup_command])
		self.run_setup_command(setup_command, console_appender)

	def run_setup_command(self, setup_command, console_appender):
		if setup_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Setup, setup_command.name)):
			raise VerificationException("Setup: %s" % setup_command.name)

	def run_compile_command(self, compile_command, console_appender):
		if compile_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Compile, compile_command.name)):
			raise VerificationException("Compiling: %s" % compile_command.name)

	def run_test_command(self, test_command, console_appender):
		if test_command.run(self.virtual_machine,
			self._get_output_handler(console_appender, ConsoleType.Test, test_command.name)):
			raise VerificationException("Testing: %s" % test_command.name)

	def verify(self, repo_uri, refs, callback, console_appender=None):
		"""Runs verification on a desired git commit"""
		try:
			verification_config = self.setup_build(repo_uri, refs, console_appender)
			self.run_compile_step(verification_config.compile_commands, console_appender)
			self.run_test_step(verification_config.test_commands, console_appender)
		except Exception as e:
			print e
			self.mark_failure(callback)
		else:
			self.mark_success(callback)

	def run_compile_step(self, compile_commands, console_appender):
		for compile_command in compile_commands:
			self.run_compile_command(compile_command, console_appender)

	def run_test_step(self, test_commands, console_appender):
		for test_command in test_commands:
			self.run_test_command(test_command, console_appender)

	def mark_success(self, callback):
		"""Calls the callback function with a success code"""
		print "Completed verification request"
		callback(VerificationResult.SUCCESS, self.rollback_virtual_machine)

	def mark_failure(self, callback):
		"""Calls the callback function with a failure code"""
		print "Failed verification request"
		callback(VerificationResult.FAILURE, self.rollback_virtual_machine)


class VagrantBuildCore(VirtualMachineBuildCore):
	def __init__(self, vagrant, uri_translator=None):
		super(VagrantBuildCore, self).__init__(vagrant, uri_translator)
		self.source_dir = os.path.join(vagrant.vm_directory, "source")

	def setup(self):
		self.virtual_machine.spawn()

	def teardown(self):
		self.virtual_machine.teardown()

	def rollback_virtual_machine(self):
		self.virtual_machine.sandbox_rollback()


class OpenstackBuildCore(VirtualMachineBuildCore):
	def __init__(self, openstack_vm, uri_translator):
		super(OpenstackBuildCore, self).__init__(openstack_vm, uri_translator)

	def setup(self):
		self.virtual_machine.wait_until_ready()

	def teardown(self):
		self.virtual_machine.delete()

	def rollback_virtual_machine(self):
		self.virtual_machine.rebuild()

	def setup_build(self, repo_uri, refs, console_appender=None):
		verification_config = super(VirtualMachineBuildCore, self).setup_build(repo_uri, refs)
		self.setup_virtual_machine(repo_uri, refs, console_appender)
		return verification_config

	def setup_virtual_machine(self, repo_uri, refs, console_appender):
		checkout_url = self.uri_translator.translate(repo_uri)
		if self.virtual_machine.remote_checkout(checkout_url, refs).returncode:
			raise VerificationException("Setup: git checkout")
		super(OpenstackBuildCore, self).setup_virtual_machine(console_appender)


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
