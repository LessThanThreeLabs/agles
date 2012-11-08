import os
import shutil

import yaml

from git import Repo

from model_server.build_outputs.update_handler import Console
from verification_config import VerificationConfig
from verification_result import VerificationResult


class BuildVerifier(object):
	def __init__(self, vagrant_wrapper):
		self.vagrant_wrapper = vagrant_wrapper
		self.source_dir = os.path.join(vagrant_wrapper.get_vm_directory(), "source")

	def setup(self):
		self.vagrant_wrapper.spawn()

	def teardown(self):
		self.vagrant_wrapper.teardown()

	def verify(self, repo_uri, refs, callback, console_appender=None):
		"""Runs verification on a desired git commit"""
		try:
			self.checkout_refs(repo_uri, refs)
			self.setup_vagrant_wrapper(console_appender)
			verification_config = self.get_verification_configurations()
			self.run_build_step(verification_config.build_commands, console_appender)
			self.run_test_step(verification_config.test_commands, console_appender)
		except VerificationException, e:
			self._mark_failure(callback, e)
		else:
			self._mark_success(callback)

	def checkout_refs(self, repo_uri, refs):
		source_repo = Repo(repo_uri)
		ref = refs[0]
		self.checkout_ref(source_repo, ref)
		for ref in refs[1:]:
			source_repo.git.merge(ref)

	def checkout_ref(self, repo, ref):
		if os.access(self.source_dir, os.F_OK):
			shutil.rmtree(self.source_dir)
		dest_repo = repo.clone(self.source_dir)
		dest_repo.git.fetch("origin", ref)
		dest_repo.git.checkout("FETCH_HEAD")

	def _get_output_handler(self, console_appender, console):
		return console_appender(console) if console_appender else None

	def setup_vagrant_wrapper(self, console_appender):
		"""Rolls back and provisions the contained vagrant wrapper for
		analysis and test running"""
		output_handler = self._get_output_handler(console_appender, Console.Setup)
		returncode = self.vagrant_wrapper.sandbox_rollback().returncode
		if returncode != 0:
			raise VerificationException("vm rollback", returncode=returncode)
		returncode = self.vagrant_wrapper.provision(output_handler=output_handler,
			role="verification_box_run").returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def get_verification_configurations(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying"""
		config_path = os.path.join(self.source_dir, "agles_config.yml")
		if os.access(config_path, os.F_OK):
			with open(config_path) as config_file:
				config = yaml.load(config_file.read())
		else:
			config = dict()
		verification_config = VerificationConfig(config.get("build"), config.get("test"))
		return verification_config

	def run_build_step(self, build_commands, console_appender):
		for build_command in build_commands:
			if build_command.run(self.vagrant_wrapper,
				self._get_output_handler(console_appender, Console.Build)):
				raise VerificationException("build")

	def run_test_step(self, test_commands, console_appender):
		for test_command in test_commands:
			if test_command.run(self.vagrant_wrapper,
				self._get_output_handler(console_appender, Console.Test)):
				raise VerificationException("test")

	def _mark_success(self, callback):
		"""Calls the callback function with a success code"""
		print "Completed build request"
		callback(VerificationResult.SUCCESS)

	def _mark_failure(self, callback, exception):
		"""Calls the callback function with a failure code"""
		print "Failed build request: " + str(exception)
		callback(VerificationResult.FAILURE)


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
