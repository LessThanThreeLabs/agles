import os
import shutil

import yaml

from git import Repo

from model_server.build.update_handler import Console
from remote_linter import VagrantLinter
from remote_test_runner import VagrantNoseRunner
from verification_result import VerificationResult


class BuildVerifier(object):
	def __init__(self, vagrant):
		self.vagrant = vagrant
		self.source_dir = os.path.join(vagrant.vm_directory, "source")

	def setup(self):
		self.vagrant.spawn()

	def teardown(self):
		self.vagrant.teardown()

	def verify(self, repo_uri, refs, callback, console_appender=None):
		"""Runs verification on a desired git commit"""
		try:
			self.checkout_refs(repo_uri, refs)
			self.setup_vagrant(console_appender)
			configuration = self.get_build_configuration()
			self.run_linter(configuration)
			self.run_tests(configuration)
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

	def setup_vagrant(self, console_appender):
		"""Rolls back and provisions the contained vagrant vm for
		analysis and test running"""
		output_handler = self._get_output_handler(console_appender, Console.Setup)
		returncode = self.vagrant.sandbox_rollback().returncode
		if returncode != 0:
			raise VerificationException("vm rollback", returncode=returncode)
		returncode = self.vagrant.provision(
			stdout_handler=output_handler, stderr_handler=output_handler).returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def get_build_configuration(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying"""
		config_path = os.path.join(self.source_dir, "agles_config.yml")
		if not os.access(config_path, os.F_OK):
			return None
		with open(config_path) as config_file:
			config = yaml.load(config_file.read())
		return config.get("build")

	def run_linter(self, configuration):
		"""Delegates to VagrantLinter to run and parse pylint output"""
		errors = VagrantLinter(self.vagrant).run()
		if errors:
			raise VerificationException("pylint linting", details=errors)

	def run_tests(self, configuration):
		"""Delegates to VagrantNoseRunner to run nose and parse xunit output"""
		test_results = VagrantNoseRunner(self.vagrant).run()
		if test_results:
			for suite in test_results:
				if suite.errors > 0 or suite.failures > 0:
					raise VerificationException("nosetests",
						details={"errors": suite.errors, "failures": suite.failures})
		else:
			print "No test results found"

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
