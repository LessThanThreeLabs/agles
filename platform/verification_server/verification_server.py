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
		self.spawn_listener()

	def teardown(self):
		"""Tears down the virtual machine and stops the listener thread for this object
		"""
		self.rabbit_connection.cancel()
		self.rabbit_connection.close()
		self.vagrant.teardown()
		configfile = os.path.join(self.vagrant.vm_directory, "repo_config.yml")
		if os.access(configfile, os.F_OK):
			os.remove(configfile)

	def spawn_listener(self):
		"""Begins a subprocess that listens for build events
		"""
		listener = Process(target=self._listen)
		listener.start()

	def _listen(self):
		"""Listen for verification events
		"""
		print "Listening for verification requests"
		self.request_listener.start_consuming()

	def request_callback(self, ch, method, properties, body):
		"""Respond to a verification event, begin verifying
		"""
		(repo_hash, sha, ref) = msgpack.unpackb(body)
		self.verify(repo_hash, sha, ref, ch, method)

	def verify(self, repo_hash, sha, ref, ch, method):
		"""Runs verification on a desired git commit
		"""
		repo_address = self.get_repo_address(repo_hash)

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
						errors)
			self.vagrant.ssh_call("find /opt/mysource -name \"tests\" |" +
					"nosetests  --with-xunit --xunit-file=/vagrant/nosetests.xml")
			test_results = XunitParser().parse_file(
					os.path.join(self.vagrant.vm_directory, "nosetests.xml"))
			for suite in test_results:
				if suite.errors > 0 or suite.failures > 0:
					raise Exception("Test failure detected in suite " + suite['name'])
		except:
			self.mark_failure(repo_hash, sha, ref, ch, method)
		else:
			self.mark_success(repo_hash, sha, ref, ch, method)
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

	def mark_success(self, repo_hash, sha, ref, ch, method):
		"""Send an event denoting verification success and ack
		"""
		print "Completed build request " + str((repo_hash, sha, ref))
		self.responder.basic_publish(exchange='',
				routing_key=verification_results_queue_name,
				body=msgpack.packb({(repo_hash, sha, ref): 0}),
				properties=pika.BasicProperties(
						delivery_mode=2,  # make message persistent
				))
		ch.basic_ack(delivery_tag=method.delivery_tag)

	def mark_failure(self, repo_hash, sha, ref, ch, method):
		"""Send an event denoting verification failure and ack
		"""
		print "Failed build request " + str((repo_hash, sha, ref))
		self.responder.basic_publish(exchange='',
				routing_key=verification_results_queue_name,
				body=msgpack.packb({(repo_hash, sha, ref): 1}),
				properties=pika.BasicProperties(
						delivery_mode=2,  # make message persistent
				))
		ch.basic_ack(delivery_tag=method.delivery_tag)
