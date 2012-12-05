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

	def up(self, provision=True, output_handler=None):
		return self.vagrant.up(provision=provision, output_handler=output_handler)

	def halt(self, force=False, output_handler=None):
		return self.vagrant.halt(force=False, output_handler=output_handler)

	def destroy(self, output_handler=None):
		return self.vagrant.destroy(output_handler=output_handler)

	def provision(self, role=None, output_handler=None):
		self.vagrant.vagrant_env["AGLES_ROLE"] = role
		results = self.vagrant.provision(output_handler=output_handler)
		del self.vagrant.vagrant_env["AGLES_ROLE"]
		return results

	def ssh_call(self, command, output_handler=None):
		return self.vagrant.ssh_call(command, output_handler=output_handler)

	def vbox_call(self, command, output_handler=None):
		return self.vagrant.vbox_call(command, output_handler=output_handler)

	def sandbox_on(self, output_handler=None):
		return self.vagrant.sandbox_on(output_handler=output_handler)

	def sandbox_off(self, output_handler=None):
		return self.vagrant.sandbox_off(output_handler=output_handler)

	def sandbox_rollback(self, output_handler=None):
		return self.vagrant.sandbox_rollback(output_handler=output_handler)

	def get_vm_directory(self):
		return self.vagrant.get_vm_directory()

	def spawn(self, output_handler=None):
		if not os.access(self.get_vm_directory(), os.F_OK):
			os.makedirs(self.get_vm_directory())
		while not self.vagrant.status() == "running":
			self.teardown()
			print "Spawning vm at " + self.get_vm_directory()
			if self.init(output_handler).returncode != 0:
				raise VagrantException(self.vagrant, "Failed to initialize vagrant")
			if self.up(False, output_handler).returncode != 0:
				raise VagrantException(self.vagrant, "Failed to start vagrant vm")
		if self.vbox_call("/usr/bin/sudo dhclient").returncode != 0:
			raise VagrantException(self.vagrant, "Failed to verify DHCP server on vm")
		if self.sandbox_on(output_handler).returncode != 0:
			raise VagrantException(self.vagrant, "Failed to initialize sandbox on vm")
		print "Launched vm at: " + self.get_vm_directory()

	def teardown(self, output_handler=None):
		vagrantfile = os.path.join(self.get_vm_directory(), "Vagrantfile")
		if os.access(vagrantfile, os.F_OK):
			print "Tearing down existing vm at " + self.get_vm_directory()
			if self.destroy(output_handler).returncode != 0:
				raise VagrantException(self, "Failed to tear down existing vm")
			os.remove(vagrantfile)

	def safe_rollback(self, output_handler=None):
		if self.sandbox_rollback(output_handler).returncode != 0:
			raise VagrantException(self.vagrant, "Failed to roll back vm")
		if self.vbox_call("/usr/bin/sudo dhclient").returncode != 0:
			raise VagrantException(self.vagrant, "Failed to verify DHCP server on vm")


class VagrantException(Exception):
	def __init__(self, vagrant, message):
		self.vagrant = vagrant
		self.message = message

	def __str__(self):
		return "%s: (%s, %s)" % (self.message, self.vagrant.box_name, self.vagrant.get_vm_directory())
