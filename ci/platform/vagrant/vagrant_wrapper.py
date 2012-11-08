import os

from time import sleep

from vagrant import Vagrant


class VagrantWrapper(object):
	def __init__(self, vagrant):
		self.vagrant = vagrant

	@classmethod
	def vm(cls, vm_directory, box_name):
		return VagrantWrapper(Vagrant(vm_directory, box_name))

	def init(self, output_handler=None):
		return self.vagrant.init(output_handler=output_handler)

	def up(self, output_handler=None):
		return self.vagrant.up(output_handler=output_handler)

	def destroy(self, output_handler=None):
		return self.vagrant.destroy(output_handler=output_handler)

	def provision(self, output_handler=None, role=None):
		self.vagrant.vagrant_env["AGLES_ROLE"] = role
		results = self.vagrant.provision(output_handler=output_handler)
		del self.vagrant.vagrant_env["AGLES_ROLE"]
		return results

	def ssh_call(self, command, output_handler=None):
		return self.vagrant.ssh_call(command, output_handler=output_handler)

	def sandbox_on(self, output_handler=None):
		return self.vagrant.sandbox_on(output_handler=output_handler)

	def sandbox_off(self, output_handler=None):
		return self.vagrant.sandbox_off(output_handler=output_handler)

	def sandbox_rollback(self, output_handler=None):
		return self.vagrant.sandbox_rollback(output_handler=output_handler)

	def get_vm_directory(self):
		return self.vagrant.get_vm_directory()

	def spawn(self, output_handler=None):
		self.teardown()
		print "Spawning vm at " + self.get_vm_directory()
		if not os.access(self.get_vm_directory(), os.F_OK):
			os.mkdir(self.get_vm_directory())

		if self.init(output_handler).returncode != 0:
			raise VagrantException(self.vagrant, "Couldn't initialize vagrant")
		if self.up(output_handler).returncode != 0:
			raise VagrantException(self.vagrant, "Couldn't start vagrant vm")
		sleep(1)  # TODO (bbland): decide if this is necessary
		if self.sandbox_on(output_handler).returncode != 0:
			raise VagrantException(self.vagrant, "Couldn't initialize sandbox on vm")
		print "Launched vm at: " + self.get_vm_directory()

	def teardown(self, output_handler=None):
		vagrantfile = os.path.join(self.get_vm_directory(), "Vagrantfile")
		if os.access(vagrantfile, os.F_OK):
			print "Tearing down existing vm at " + self.get_vm_directory()
			if self.destroy(output_handler).returncode != 0:
				raise VagrantException(self, "Couldn't tear down existing vm")
			os.remove(vagrantfile)


class VagrantException(Exception):
	def __init__(self, vagrant, message):
		self.vagrant = vagrant
		self.message = message

	def __str__(self):
		return "%s: (%s, %s)" % (self.message, self.vagrant.box_name, self.vagrant.get_vm_directory())
