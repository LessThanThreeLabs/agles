import os
import shutil

import yaml

from git import Repo
from kombu import Producer

from handler import MessageHandler
from model_server import ModelServer
from remote_linter import VagrantLinter
from remote_test_runner import VagrantNoseRunner
from settings.verification_server import *
from verification_result import *


class VerificationRequestHandler(MessageHandler):
	"""Handles verification requests sent from verification masters
	and triggers a Verify on the commit list.
	"""
	def __init__(self, vagrant):
		super(VerificationRequestHandler, self).__init__(verification_request_queue)
		self.vagrant = vagrant
		self.source_dir = os.path.join(vagrant.vm_directory, "source")

	def bind(self, channel):
		self.producer = Producer(channel, serializer='msgpack')
		self.vagrant.spawn()
		super(VerificationRequestHandler, self).bind(channel)

	def handle_message(self, body, message):
		"""Respond to a verification event, begin verifying"""
		repo_hash, commit_list = body
		print "Processing verification request: " + str((repo_hash, commit_list,))
		repo_address = self.get_repo_address(repo_hash)
		verify_callback = self.make_verify_callback(repo_hash, commit_list, message)
		self.verify(repo_address, commit_list, verify_callback)

	def make_verify_callback(self, repo_hash, commit_list, message):
		"""Returns the default callback function to be
		called with a return value after verification.
		Sends a message denoting the return value and acks"""
		def default_verify_callback(results):
			self.producer.publish((repo_hash, commit_list, results),
				exchange=verification_results_queue.exchange,
				routing_key=verification_results_queue.routing_key,
				delivery_mode=2,  # make message persistent
			)
			message.channel.basic_ack(delivery_tag=message.delivery_tag)
		return default_verify_callback

	def verify(self, repo_address, commit_list, callback):
		"""Runs verification on a desired git commit"""
		try:
			self.checkout_commit_list(repo_address, commit_list)
			self.setup_vagrant()
			configuration = self.get_user_configuration()
			self.run_linter(configuration)
			self.run_tests(configuration)
		except VerificationException, e:
			self._mark_failure(callback, e)
		else:
			self._mark_success(callback)

	def get_repo_address(self, repo_hash):
		"""Sends out a rpc call to the model server to retrieve
		the address of a repository based on its hash"""
		with ModelServer.rpc_connect("rpc-repo-read") as model_server_rpc:
			repo_address = model_server_rpc.get_repo_address(repo_hash)
		return repo_address

	def checkout_commit_list(self, repo_address, commit_list):
		source_repo = Repo(repo_address)
		sha, ref = commit_list[0]
		self.checkout_commit(source_repo, sha)
		for sha, ref in commit_list[1:]:
			source_repo.git.merge(sha)

	def checkout_commit(self, repo, sha):
		if os.access(self.source_dir, os.F_OK):
			shutil.rmtree(self.source_dir)
		dest_repo = repo.clone(self.source_dir)
		dest_repo.git.checkout(sha)

	def setup_vagrant(self):
		"""Rolls back and provisions the contained vagrant vm for
		analysis and test running"""
		returncode = self.vagrant.sandbox_rollback().returncode
		if returncode != 0:
			raise VerificationException("vm rollback", returncode=returncode)
		returncode = self.vagrant.provision().returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def get_user_configuration(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying"""
		config_path = os.path.join(self.source_dir, "agles_config.yml")
		if not os.access(config_path, os.F_OK):
			return None
		with open(config_path) as config_file:
			config = yaml.load(config_file.read())
		return config

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
