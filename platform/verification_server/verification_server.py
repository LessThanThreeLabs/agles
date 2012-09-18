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

from multiprocessing import Process
from vagrant import Vagrant
from xunit_parser import XunitParser
from lint_parser import LintParser
from settings.rabbit import connection_parameters
from settings.model_server import repo_update_routing_key
from settings.verification_server import verification_results_queue_name, box_name


class VerificationServer(object):
	"""Verifies correctness of builds.

	Contains and controls a Vagrant virtual machine, which is used to check out,
	lint, and run tests against commits.
	"""

	def __init__(self, model_server_address, vm_directory):
		self.rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.request_listener = self.rabbit_connection.channel()
		self.request_listener.queue_declare(queue=repo_update_routing_key, durable=True)
		self.request_listener.basic_qos(prefetch_count=1)
		self.request_listener.basic_consume(self.request_callback,
				queue=repo_update_routing_key)

		self.responder = self.rabbit_connection.channel()
		self.responder.queue_declare(queue=verification_results_queue_name, durable=True)

		self.vagrant = Vagrant(vm_directory, box_name)

		self.model_server_rpc = zerorpc.Client()
		self.model_server_rpc.connect(model_server_address)

	def run(self):
		"""Spawns the virtual machine and listener thread defined for this object
		"""
		self.vagrant.spawn()
		self.listener_process = self.spawn_listener()

	def teardown(self):
		"""Tears down the virtual machine and stops the listener thread for this object
		"""
		self.listener_process.terminate()
		self.rabbit_connection.close()
		self.vagrant.teardown()
		configfile = os.path.join(self.vagrant.vm_directory, "repo_config.yml")
		if os.access(configfile, os.F_OK):
			os.remove(configfile)

	# TODO(bbland): change this logic somehow
	def spawn_listener(self):
		"""Begins a subprocess that listens for build events
		"""
		listener = Process(target=self._listen)
		listener.start()
		return listener

	def _listen(self):
		"""Listen for verification events
		"""
		print "Listening for verification requests"
		self.request_listener.start_consuming()

	def request_callback(self, channel, method, properties, body):
		"""Respond to a verification event, begin verifying
		"""
		(repo_hash, sha, ref) = msgpack.unpackb(body)
		repo_address = self.get_repo_address(repo_hash)
		verify_callback = self.get_verify_callback(repo_hash, sha, ref, channel, method)
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
		with open(os.path.join(self.vagrant.vm_directory, "repo_config.yml"), 'w') as pref_file:
			pref_file.write(self.get_git_config_yaml(repo_address, sha))

		try:
			if self.vagrant.sandbox_rollback().returncode != 0:
				raise Exception("Couldn't roll back vm: " + self.vm_directory)
			if self.vagrant.provision().returncode != 0:
				raise Exception("Couldn't provision vm: " + self.vm_directory)
			results = self.vagrant.ssh_call("find /opt/mysource -name \"*.py\" |" +
					"xargs pylint --reports=n")
			lint_parser = LintParser()
			pylint_issues = lint_parser.parse_pylint(results.stdout)
			errors = lint_parser.get_errors(pylint_issues)
			if errors:
				raise Exception("Found the following errors while running pylint:\n" +
						str(errors))
			self.vagrant.ssh_call("find /opt/mysource -name \"tests\" |" +
					"nosetests  --with-xunit --xunit-file=/vagrant/nosetests.xml")
			test_results = XunitParser().parse_file(
					os.path.join(self.vagrant.vm_directory, "nosetests.xml"))
			if test_results:
				for suite in test_results:
					if suite.errors > 0 or suite.failures > 0:
						raise Exception("Test failure detected in suite " + suite['name'])
			else:
				print "No test results found"
		except Exception as e:
			print str(e)
			self.mark_failure(callback)
		else:
			self.mark_success(callback)
		finally:
			os.remove(os.path.join(self.vagrant.vm_directory, "repo_config.yml"))

	def get_repo_address(self, repo_hash):
		"""Sends out a rpc call to the model server to retrieve
		the address of a repository based on its hash
		"""
		return self.model_server_rpc.get_repo_address(repo_hash)

	def get_git_config_yaml(self, repo_address, sha):
		"""Returns a yaml string with git configuration commands
		for provisioning a vm
		"""
		return yaml.dump({"repo_address": repo_address,
				"sha_hash": sha}, default_flow_style=False)

	def mark_success(self, callback):
		"""Calls the callback function with a success code
		"""
		print "Completed build request"
		callback(0)  # success

	def mark_failure(self, callback):
		"""Calls the callback function with a failure code
		"""
		print "Failed build request"
		callback(1)  # success
