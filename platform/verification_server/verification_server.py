import os
import pika
import msgpack
import yaml
import zerorpc

from multiprocessing import Process
from subprocess import call
from settings.rabbit import connection_parameters
from settings.model_server import repo_update_routing_key
from settings.verification_server import verification_results_queue_name, box_name


class VerificationServer(object):
	"""Verifies correctness of builds"""

	def __init__(self, model_server_address, vm_directory):
		self.rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.request_listener = self.rabbit_connection.channel()
		self.request_listener.queue_declare(queue=repo_update_routing_key, durable=True)
		self.request_listener.basic_qos(prefetch_count=1)
		self.request_listener.basic_consume(self.request_callback,
				queue=repo_update_routing_key)

		self.responder = self.rabbit_connection.channel()
		self.responder.queue_declare(queue=verification_results_queue_name, durable=True)

		self.vm_directory = vm_directory

		self.model_server_rpc = zerorpc.Client()
		self.model_server_rpc.connect(model_server_address)

	def run(self):
		self.spawn_vm()
		self.spawn_listener()

	def teardown(self):
		self.rabbit_connection.cancel()
		self.rabbit_connection.close()
		self.teardown_vm()

	def spawn_listener(self):
		listener = Process(target=self._listen)
		listener.start()

	def get_vagrant_env(self):
		vagrant_env = os.environ.copy()
		vagrant_env["AGLES_ROOT"] = os.path.realpath(os.path.pardir(os.path.pardir(__file__)))
		return vagrant_env

	def call_vagrant(self, args):
		command = ["vagrant"].extend(args)
		retval = call(command, cwd=self.vm_directory, env=self.get_vagrant_env())
		return retval

	def spawn_vm(self):
		self.teardown_vm()
		print "Spawning vm at " + self.vm_directory
		if not os.access(self.vm_directory, os.F_OK):
			os.mkdir(self.vm_directory)
		retval = self.call_vagrant(["init", box_name])
		if retval != 0:
			raise Exception("Couldn't initialize vagrant: " + self.vm_directory)
		retval = self.call_vagrant(["up"])
		if retval != 0:
			raise Exception("Couldn't start vagrant vm: " + self.vm_directory)
		retval = self.call_vagrant(["sandbox", "on"])
		if retval != 0:
			raise Exception("Couldn't initialize sandbox on vm: " + self.vm_directory)
		print "Launched vm at : " + self.vm_directory

	def teardown_vm(self):
		vagrantfile = os.path.join(self.vm_directory, "Vagrantfile")
		if os.access(vagrantfile, os.F_OK):
			print "Tearing down existing vm at " + self.vm_directory
			retval = self.call_vagrant(["destroy", "-f"])
			if retval != 0:
				raise Exception("Couldn't tear down existing vm: " + self.vm_directory)
			os.remove(vagrantfile)
		configfile = os.path.join(self.vm_directory, "repo_config.yml")
		if os.access(configfile, os.F_OK):
			os.remove(configfile)

	def _listen(self):
		print "Listening for verification requests"
		self.request_listener.start_consuming()

	def request_callback(self, ch, method, properties, body):
		(repo_hash, sha, ref) = msgpack.unpackb(body)
		self.verify(repo_hash, sha, ref, ch, method)

	def verify(self, repo_hash, sha, ref, ch, method):
		# runs verification on a desired git commit
		repo_address = self.get_repo_address(repo_hash)

		pref_file = open(os.path.join(self.vm_directory, "repo_config.yml"), 'w')
		pref_file.write(self.get_git_config_yaml(repo_address, sha))
		pref_file.close()

		retval = -1
		try:
			retval = self.call_vagrant(["sandbox", "rollback"])
			if retval != 0:
				raise Exception("Couldn't roll back vm: " + self.vm_directory)
			retval = self.call_vagrant(["provision"])
			if retval != 0:
				raise Exception("Couldn't provision vm: " + self.vm_directory)
		finally:
			os.remove(os.path.join(self.vm_directory, "repo_config.yml"))
			self.mark_success(repo_address, sha, retval, ch, method)

	def get_repo_address(self, repo_hash):
		return self.model_server_rpc.get_repo_address(repo_hash)

	def get_git_config_yaml(self, repo_address, sha):
		# returns a list of git configuration commands for provisioning a vm
		return yaml.dump({"repo_address": repo_address,
				"sha_hash": sha})

	def mark_success(self, repo_hash, sha, ref, retval, ch, method):
		print "Completed build request " + str((repo_hash, sha, ref)) + " with retval: " + str(retval)
		self.responder.basic_publish(exchange='',
				routing_key=verification_results_queue_name,
				body=msgpack.packb({(repo_hash, sha, ref): retval}),
				properties=pika.BasicProperties(
						delivery_mode=2,  # make message persistent
				))
		ch.basic_ack(delivery_tag=method.delivery_tag)
