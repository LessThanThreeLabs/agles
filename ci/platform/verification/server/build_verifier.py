import os
import shutil

import yaml

from git import Git, Repo

from model_server.build_outputs.update_handler import ConsoleType
from verification_config import VerificationConfig
from verification_result import VerificationResult


class BuildVerifier(object):
	def __init__(self, vagrant_wrapper, uri_translator):
		self.vagrant_wrapper = vagrant_wrapper
		self.uri_translator = uri_translator
		self.source_dir = os.path.join(vagrant_wrapper.get_vm_directory(), "source")

	def setup(self):
		self.vagrant_wrapper.spawn()

	def teardown(self):
		self.vagrant_wrapper.teardown()

	def verify(self, repo_uri, refs, callback, console_appender=None):
		"""Runs verification on a desired git commit"""
		try:
			self.checkout_refs(repo_uri, refs)
			self._setup_vagrant_wrapper(console_appender)
			verification_config = self.get_verification_configurations()
			self.run_compile_step(verification_config.compile_commands, console_appender)
			self.run_test_step(verification_config.test_commands, console_appender)
		except Exception, e:
			self._mark_failure(callback, e)
		else:
			self._mark_success(callback)

	def checkout_refs(self, repo_uri, refs):
		if os.access(self.source_dir, os.F_OK):
			shutil.rmtree(self.source_dir)
		checkout_url = self.uri_translator.translate(repo_uri)
		Git().clone(checkout_url, self.source_dir)
		repo = Repo(self.source_dir)
		ref = refs[0]
		repo.git.fetch("origin", ref)
		repo.git.checkout("FETCH_HEAD")
		for ref in refs[1:]:
			repo.git.merge(ref)

	def _get_output_handler(self, console_appender, type, subtype=""):
		return console_appender(type, subtype) if console_appender else None

	def _setup_vagrant_wrapper(self, console_appender):
		"""Provisions the contained vagrant wrapper for analysis and test running"""
		output_handler = self._get_output_handler(console_appender, ConsoleType.Setup, "chef")
		returncode = self.vagrant_wrapper.provision(output_handler=output_handler,
			role="verification_box_run").returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def _rollback_vagrant_wrapper(self):
		returncode = self.vagrant_wrapper.sandbox_rollback().returncode
		if returncode != 0:
			print "Failed to roll back vm"  # Should be logged somewhere
		returncode = self.vagrant_wrapper.halt(force=True).returncode
		if returncode != 0:
			print "Failed to shut down vm"  # Should be logged somewhere
		returncode = self.vagrant_wrapper.up(provision=False).returncode
		if returncode != 0:
			print "Failed to re-launch vm"  # Should be logged somewhere

	def get_verification_configurations(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying"""
		config_path = os.path.join(self.source_dir, "agles_config.yml")
		if os.access(config_path, os.F_OK):
			with open(config_path) as config_file:
				config = yaml.load(config_file.read())
		else:
			config = dict()
		verification_config = VerificationConfig(config.get("compile"), config.get("test"))
		return verification_config

	def run_compile_step(self, compile_commands, console_appender):
		for compile_command in compile_commands:
			if compile_command.run(self.vagrant_wrapper,
				self._get_output_handler(console_appender, ConsoleType.Compile, compile_command.name)):
				raise VerificationException("Compiling: %s" % compile_command.name)

	def run_test_step(self, test_commands, console_appender):
		for test_command in test_commands:
			if test_command.run(self.vagrant_wrapper,
				self._get_output_handler(console_appender, ConsoleType.Test, test_command.name)):
				raise VerificationException("Testing: %s" % test_command.name)

	def _mark_success(self, callback):
		"""Calls the callback function with a success code"""
		print "Completed verification request"
		callback(VerificationResult.SUCCESS, self._rollback_vagrant_wrapper)

	def _mark_failure(self, callback, exception):
		"""Calls the callback function with a failure code"""
		print "Failed verification request: " + str(exception)
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
