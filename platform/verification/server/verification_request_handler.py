import os
import shutil

import yaml

from git import Repo
from kombu import Producer

from constants import BuildStatus
from handler import MessageHandler
from model_server import ModelServer
from model_server.build.update_handler import Console
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
		change_id, commit_list = body
		build_id = self._create_build(change_id, commit_list)
		print "Processing verification request: " + str((change_id, commit_list,)) + " as build: " + str(build_id)
		repo_uri = self.get_repo_uri(commit_list[0])
		refs = self._get_ref_list(commit_list)
		with ModelServer.rpc_connect("build", "update") as model_server_rpc:
			stdout_handler = self._make_output_appender(model_server_rpc, build_id, Console.Stdout)
			stderr_handler = self._make_output_appender(model_server_rpc, build_id, Console.Stderr)
			verify_callback = self.make_verify_callback(change_id, commit_list, build_id, model_server_rpc, message)
			self.verify(repo_uri, refs, verify_callback,
				stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def make_verify_callback(self, change_id, commit_list, build_id, model_server_rpc, message):
		"""Returns the default callback function to be
		called with a return value after verification.
		Sends a message denoting the return value and acks"""
		def default_verify_callback(results):
			self.producer.publish((change_id, commit_list, results),
				exchange=verification_results_queue.exchange,
				routing_key=verification_results_queue.routing_key,
				delivery_mode=2,  # make message persistent
			)
			model_server_rpc.flush_console_output(build_id, Console.Stdout)
			model_server_rpc.flush_console_output(build_id, Console.Stderr)
			status = BuildStatus.COMPLETE if results == VerificationResult.SUCCESS else BuildStatus.FAILED
			model_server_rpc.mark_build_finished(build_id, status)
			message.channel.basic_ack(delivery_tag=message.delivery_tag)
		return default_verify_callback

	def _create_build(self, change_id, commit_list):
		with ModelServer.rpc_connect("build", "create") as model_server_rpc:
			return model_server_rpc.create_build(change_id, commit_list)

	def verify(self, repo_uri, refs, callback, stdout_handler=None, stderr_handler=None):
		"""Runs verification on a desired git commit"""
		try:
			self.checkout_refs(repo_uri, refs)
			self.setup_vagrant(stdout_handler, stderr_handler)
			configuration = self.get_user_configuration()
			self.run_linter(configuration)
			self.run_tests(configuration)
		except VerificationException, e:
			self._mark_failure(callback, e)
		else:
			self._mark_success(callback)

	def get_repo_uri(self, commit_id):
		"""Sends out a rpc call to the model server to retrieve
		the uri of a repository for a commit"""
		with ModelServer.rpc_connect("repo", "read") as model_server_rpc:
			return model_server_rpc.get_repo_uri(commit_id)

	def _get_ref_list(self, commit_list):
		with ModelServer.rpc_connect("repo", "read") as model_server_rpc:
			return [model_server_rpc.get_commit_attributes(commit)[2] for commit in commit_list]

	def checkout_refs(self, repo_uri, refs):
		source_repo = Repo(repo_uri)
		ref = refs[0]
		self.checkout_commit(source_repo, ref)
		for ref in refs[1:]:
			source_repo.git.merge(ref)

	def checkout_commit(self, repo, ref):
		if os.access(self.source_dir, os.F_OK):
			shutil.rmtree(self.source_dir)
		dest_repo = repo.clone(self.source_dir)
		dest_repo.git.fetch("origin", ref)
		dest_repo.git.checkout("FETCH_HEAD")

	def setup_vagrant(self, stdout_handler, stderr_handler):
		"""Rolls back and provisions the contained vagrant vm for
		analysis and test running"""
		returncode = self.vagrant.sandbox_rollback().returncode
		if returncode != 0:
			raise VerificationException("vm rollback", returncode=returncode)
		returncode = self.vagrant.provision(
			stdout_handler=stdout_handler, stderr_handler=stderr_handler).returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def _make_output_appender(self, model_server_rpc, build_id, console):
		def append_output(line):
			model_server_rpc.append_console_output(build_id, line, console)
		return append_output

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
