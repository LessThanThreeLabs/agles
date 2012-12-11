import os
import shutil

import yaml

from git import Git, Repo

from model_server.build_outputs import ConsoleType
from vagrant.vagrant_command import NullVagrantCommand
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
			repo.git.merge(ref)

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


class VagrantBuildCore(BuildCore):
	def __init__(self, vagrant_wrapper, uri_translator=None):
		super(VagrantBuildCore, self).__init__(uri_translator)
		self.vagrant_wrapper = vagrant_wrapper
		self.source_dir = os.path.join(vagrant_wrapper.get_vm_directory(), "source")

	def setup_build(self, repo_uri, refs, console_appender=None):
		verification_config = super(VagrantBuildCore, self).setup_build(repo_uri, refs)
		self._declare_setup_commands(console_appender)
		self._setup_vagrant_wrapper(console_appender)
		return verification_config

	def _get_output_handler(self, console_appender, type, subtype=""):
		return console_appender(type, subtype) if console_appender else None

	def _declare_setup_commands(self, console_appender):
		if console_appender:
			self.declare_commands(console_appender, ConsoleType.Setup, [NullVagrantCommand("chef")])

	def declare_commands(self, console_appender, console_type, commands):
		command_names = [command.name for command in commands]
		self._get_output_handler(console_appender, console_type).declare_commands(command_names)

	def _setup_vagrant_wrapper(self, console_appender):
		"""Provisions the contained vagrant wrapper for analysis and test running"""
		output_handler = self._get_output_handler(console_appender, ConsoleType.Setup, "chef")
		returncode = self.vagrant_wrapper.provision(role="verification_box_run",
			output_handler=output_handler).returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def _rollback_vagrant_wrapper(self):
		self.vagrant_wrapper.safe_rollback()

	def run_compile_command(self, compile_command, console_appender):
		if compile_command.run(self.vagrant_wrapper,
			self._get_output_handler(console_appender, ConsoleType.Compile, compile_command.name)):
			raise VerificationException("Compiling: %s" % compile_command.name)

	def run_test_command(self, test_command, console_appender):
		if test_command.run(self.vagrant_wrapper,
			self._get_output_handler(console_appender, ConsoleType.Test, test_command.name)):
			raise VerificationException("Testing: %s" % test_command.name)

	def mark_success(self, callback):
		"""Calls the callback function with a success code"""
		print "Completed verification request"
		callback(VerificationResult.SUCCESS, self._rollback_vagrant_wrapper)

	def mark_failure(self, callback):
		"""Calls the callback function with a failure code"""
		print "Failed verification request"
		callback(VerificationResult.FAILURE, self._rollback_vagrant_wrapper)


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
