# verification_server.py - Responds to repo update events and verifies build correctness

"""This file contains the logic required to verify the correctness of builds.

No methods aside from run and teardown should be called directly, as the
listener thread should respond to events by running and verifying builds on
a spawned virtual machine.
"""

import os
import pika
import msgpack
import yaml
import zerorpc

from util.vagrant import Vagrant
from remote_test_runner import VagrantNoseRunner
from remote_linter import VagrantLinter
from settings.rabbit import connection_parameters
from settings.model_server import repo_update_routing_key
from settings.verification_server import verification_results_queue_name, box_name


class VerificationServer(object):
	"""Verifies correctness of builds.

	Contains and controls a Vagrant virtual machine, which is used to check out,
	lint, and run tests against commits.
	"""

	def __init__(self, model_server_address, vm_directory):
		self.model_server_address = model_server_address

		self.vagrant = Vagrant(vm_directory, box_name)

		self.rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.responder = self.rabbit_connection.channel()
		self.responder.queue_declare(queue=verification_results_queue_name, durable=True)

	def run(self):
		self.vagrant.spawn()
		self.listen()

	def listen(self):
		"""Listen for verification events
		"""
		request_listener = self.rabbit_connection.channel()
		request_listener.queue_declare(queue=repo_update_routing_key, durable=True)
		request_listener.basic_qos(prefetch_count=1)
		print "Listening for verification requests"
		request_listener.basic_consume(self.request_callback,
				queue=repo_update_routing_key)
		request_listener.start_consuming()

	def request_callback(self, channel, method, properties, body):
		"""Respond to a verification event, begin verifying
		"""
		(repo_hash, sha, ref) = msgpack.unpackb(body)
		print "Processing verification request: " + str((repo_hash, sha, ref))
		repo_address = self.get_repo_address(repo_hash)
		verify_callback = self.make_verify_callback(repo_hash, sha, ref, channel, method)
		self.verify(repo_address, sha, ref, verify_callback)

	def make_verify_callback(self, repo_hash, sha, ref, channel, method):
		"""Returns the default callback function to be
		called with a return value after verification.
		Sends a message denoting the return value and acks
		"""
		def default_verify_callback(retval):
			self.responder.basic_publish(exchange='',
				routing_key=verification_results_queue_name,
				body=msgpack.packb({(repo_hash, sha, ref): retval}),
				properties=pika.BasicProperties(
						delivery_mode=2,  # make message persistent
				))
			channel.basic_ack(delivery_tag=method.delivery_tag)
		return default_verify_callback

	def verify(self, repo_address, sha, ref, callback):
		"""Runs verification on a desired git commit
		"""
		self.write_git_config_yaml(repo_address, sha)
		try:
			self.setup_vagrant()
			configuration = self.get_user_configuration()
			self.run_linter(configuration)
			self.run_tests(configuration)
		except VerificationException, e:
			self._mark_failure(callback, e)
		else:
			self._mark_success(callback)
		finally:
			os.remove(os.path.join(self.vagrant.vm_directory, "repo_config.yml"))

	def get_repo_address(self, repo_hash):
		"""Sends out a rpc call to the model server to retrieve
		the address of a repository based on its hash
		"""
		model_server_rpc = zerorpc.Client()
		model_server_rpc.connect(self.model_server_address)
		try:
			model_server_rpc._zerorpc_ping()
		except zerorpc.exceptions.TimeoutExpired:
			# recover from timeouts
			pass
		repo_address = model_server_rpc.get_repo_address(repo_hash)
		model_server_rpc.close()
		return repo_address

	def write_git_config_yaml(self, repo_address, sha):
		"""Writes out the git repository config yaml into the vagrant
		shared directory for the purpose of vm provisioning
		"""
		with open(os.path.join(self.vagrant.vm_directory, "repo_config.yml"), 'w') as pref_file:
			pref_file.write(self.get_git_config_yaml(repo_address, sha))

	def get_git_config_yaml(self, repo_address, sha):
		"""Returns a yaml string with git configuration commands
		for provisioning a vm
		"""
		return yaml.dump({"repo_address": repo_address,
				"sha_hash": sha}, default_flow_style=False)

	def setup_vagrant(self):
		"""Rolls back and provisions the contained vagrant vm for
		analysis and test running
		"""
		returncode = self.vagrant.sandbox_rollback().returncode
		if returncode != 0:
			raise VerificationException("vm rollback", returncode=returncode)
		returncode = self.vagrant.provision().returncode
		if returncode != 0:
			raise VerificationException("vm provisioning", returncode=returncode)

	def get_user_configuration(self):
		"""Reads in the yaml config file contained in the checked
		out user repository which this server is verifying
		"""
		config_path = os.path.join(self.vagrant.vm_directory, "agles_config.yml")
		if not os.access(config_path, os.F_OK):
			return None
		with open(config_path) as config_file:
			config = yaml.load(config_file.read())
		return config

	def run_linter(self, configuration):
		"""Delegates to VagrantLinter to run and parse pylint output
		"""
		errors = VagrantLinter(self.vagrant).run()
		if errors:
			raise VerificationException("pylint linting", details=errors)

	def run_tests(self, configuration):
		"""Delegates to VagrantNoseRunner to run nose and parse xunit output
		"""
		test_results = VagrantNoseRunner(self.vagrant).run()
		if test_results:
			for suite in test_results:
				if suite.errors > 0 or suite.failures > 0:
					raise VerificationException("nosetests",
							details={"errors": suite.errors, "failures": suite.failures})
		else:
			print "No test results found"

	def _mark_success(self, callback):
		"""Calls the callback function with a success code
		"""
		print "Completed build request"
		callback(0)  # success

	def _mark_failure(self, callback, exception):
		"""Calls the callback function with a failure code
		"""
		print "Failed build request: " + str(exception)
		callback(1)  # success


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
