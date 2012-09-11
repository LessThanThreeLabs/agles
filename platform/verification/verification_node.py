import os
import pika
import msgpack
import yaml

from multiprocessing import Process, Manager
from subprocess import call
from settings.verification_node import connection_parameters, queue_name, box_name, vm_count


class VerificationNode(object):
	"""Verifies correctness of builds"""

	def __init__(self):
		self.connection = pika.BlockingConnection(connection_parameters)
		manager = Manager()
		self.current_build_requests = manager.dict()
		self.free_vms = manager.dict()

	def run(self):
		self.spawn_vm_pool()
		self.spawn_listener()

	def teardown(self):
		self.connection.close()
		for vm_identifier in self.free_vms.keys():
			self.teardown_vm(vm_identifier)

	def spawn_vm_pool(self):
		for x in range(vm_count):
			self.spawn_vm(str(x))

	def spawn_listener(self):
		listener = Process(target=self._listen)
		listener.start()

	def spawn_vm(self, vm_identifier):
		self.teardown_vm(vm_identifier)
		if not os.access(vm_identifier, os.F_OK):
			os.mkdir(vm_identifier)
		retval = call(["vagrant", "init", box_name], cwd=vm_identifier)
		if retval != 0:
			raise Exception("Couldn't initialize vagrant: " + vm_identifier)
		retval = call(["vagrant", "up"], cwd=vm_identifier)
		if retval != 0:
			raise Exception("Couldn't start vagrant vm: " + vm_identifier)
		retval = call(["vagrant", "sandbox", "on"], cwd=vm_identifier)
		if retval != 0:
			raise Exception("Couldn't initialize sandbox on vm: " + vm_identifier)
		print "Launched VM with identifier : " + vm_identifier
		self.free_vms[vm_identifier] = 1

	def teardown_vm(self, vm_identifier):
		vagrantfile = os.path.join(vm_identifier, "Vagrantfile")
		if os.access(vagrantfile, os.F_OK):
			retval = call(["vagrant", "destroy", "-f"], cwd=vm_identifier)
			if retval != 0:
				raise Exception("Couldn't tear down existing vm: " + vm_identifier)
			os.remove(vagrantfile)
		configfile = os.path.join(vm_identifier, "repo_config.yml")
		if os.access(configfile, os.F_OK):
			os.remove(configfile)

	def _listen(self):
		request_listener = self.connection.channel()
		request_listener.queue_declare(queue=queue_name, durable=True)
		request_listener.basic_qos(prefetch_count=vm_count)
		request_listener.basic_consume(self.request_callback,
				queue=queue_name)
		print "Listening for verification requests"
		request_listener.start_consuming()

	def request_callback(self, ch, method, properties, body):
		[repo_address, sha] = msgpack.unpackb(body)
		self.verify(repo_address, sha, ch, method)

	def can_handle_requests(self):
		# temporary no-op, should use semaphores, load calculation in the future
		return True

	def verify(self, repo_address, sha, ch, method):
		# spawns verify event
		vm_identifier = self.free_vms.popitem()[0]
		verify_process = Process(target=self._verify, args=(vm_identifier, repo_address, sha, ch, method))
		self.current_build_requests[vm_identifier] = [repo_address, sha]
		verify_process.start()

	def _verify(self, vm_identifier, repo_address, sha, ch, method):
		# runs verification on a desired git commit
		pref_file = open(os.path.join(vm_identifier, "repo_config.yml"), 'w')
		pref_file.write(self.get_git_config_yaml(repo_address, sha))
		pref_file.close()

		retval = -1
		try:
			retval = call(["vagrant", "sandbox", "rollback"], cwd=vm_identifier)
			if retval != 0:
				raise Exception("Couldn't roll back vm: " + vm_identifier)
			retval = call(["vagrant", "provision"], cwd=vm_identifier)
			if retval != 0:
				raise Exception("Couldn't provision vm: " + vm_identifier)
		finally:
			os.remove(os.path.join(vm_identifier, "repo_config.yml"))
			self.mark_success(vm_identifier, repo_address, sha, retval, ch, method)

	def get_git_config_yaml(self, repo_address, sha):
		# returns a list of git configuration commands for provisioning a vm
		return yaml.dump({"repo_address": repo_address,
				"sha_hash": sha})

	def mark_success(self, vm_identifier, repo_address, sha, retval, ch, method):
		print "Completed build request " + repo_address + " " + sha + " with retval: " + str(retval)
		del self.current_build_requests[vm_identifier]
		self.free_vms[vm_identifier] = 1
		ch.basic_ack(delivery_tag=method.delivery_tag)
