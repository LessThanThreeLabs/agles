# vagrant.py - Defines a python object wrapper around the vagrant command line interface

"""An interface for Vagrant over the command line.
"""

import json
import os
import re

from virtual_machine import VirtualMachine


class Vagrant(VirtualMachine):
	"""A wrapper for a Vagrant virtual machine"""
	def __init__(self, vm_directory, box_name):
		super(Vagrant, self).__init__(vm_directory)
		self.box_name = box_name
		self.ssh_config = None

	def status(self):
		status_output = self._vagrant_call("status").output
		match = re.search("default\\s+(.*)", status_output, re.MULTILINE)
		return match.group(1).rstrip() if match else "not created"

	def init(self, output_handler=None):
		return self._vagrant_call("init", self.box_name, output_handler=output_handler)

	def up(self, provision=True, output_handler=None):
		if not provision:
			return self._vagrant_call("up", "--no-provision", output_handler=output_handler)
		return self._vagrant_call("up", output_handler=output_handler)

	def halt(self, force=False, output_handler=None):
		if force:
			return self._vagrant_call("halt", "-f", output_handler=output_handler)
		return self._vagrant_call("halt", output_handler=output_handler)

	def destroy(self, output_handler=None):
		self._invalidate_ssh_config()
		return self._vagrant_call("destroy", "-f", output_handler=output_handler)

	def provision(self, role=None, output_handler=None):
		return self._vagrant_call("provision", output_handler=output_handler, env={"KOALITY_ROLE": role})

	def ssh_call(self, command, output_handler=None):
		if not self.ssh_config:
			self._generate_ssh_config()
		return self.call(["ssh", "default", "-q", "-F", self.ssh_config, command], output_handler=output_handler)

	def vbox_call(self, command, output_handler=None):
		vbox_id = self._get_vbox_id()
		return self._vagrant_call("VBoxManage", "guestcontrol", vbox_id, "exec",
			"--username", "vagrant", "--password", "vagrant",
			"--wait-stdout", "--wait-stderr",
			*command.split(), output_handler=output_handler)

	def sandbox_on(self, output_handler=None):
		return self._vagrant_call("sandbox", "on", output_handler=output_handler)

	def sandbox_off(self, output_handler=None):
		return self._vagrant_call("sandbox", "off", output_handler=output_handler)

	def sandbox_rollback(self, output_handler=None):
		if self._sandbox_rollback(output_handler).returncode != 0:
			raise VagrantException(self, "Failed to roll back vm")
		if self.vbox_call("/usr/bin/sudo dhclient eth0").returncode != 0:
			raise VagrantException(self, "Failed to verify DHCP server on vm")

	def spawn(self, output_handler=None):
		if not os.access(self.vm_directory, os.F_OK):
			os.makedirs(self.vm_directory)
		while not self.status() == "running":
			self.teardown()
			print "Spawning vm at " + self.vm_directory
			if self.init(output_handler).returncode != 0:
				raise VagrantException(self, "Failed to initialize vagrant")
			if self.up(False, output_handler).returncode != 0:
				raise VagrantException(self, "Failed to start vagrant vm")
		if self.vbox_call("/usr/bin/sudo dhclient eth0").returncode != 0:
			raise VagrantException(self, "Failed to verify DHCP server on vm")
		if self.sandbox_on(output_handler).returncode != 0:
			raise VagrantException(self, "Failed to initialize sandbox on vm")
		print "Launched vm at: " + self.vm_directory

	def teardown(self, output_handler=None):
		vagrantfile = os.path.join(self.vm_directory, "Vagrantfile")
		if os.access(vagrantfile, os.F_OK):
			print "Tearing down existing vm at " + self.vm_directory
			if self.destroy(output_handler).returncode != 0:
				raise VagrantException(self, "Failed to tear down existing vm")
			os.remove(vagrantfile)

	def _sandbox_rollback(self, output_handler=None):
		return self._vagrant_call("sandbox", "rollback", output_handler=output_handler)

	def _vagrant_call(self, *args, **kwargs):
		command = ["vagrant"] + list(args)
		return self.call(command, **kwargs)

	def _get_vbox_id(self):
		with open(os.path.join(self.vm_directory, ".vagrant")) as json_file:
			return json.load(json_file)["active"]["default"]

	def _generate_ssh_config(self):
		with open(os.path.join(self.vm_directory, ".vagrant_ssh"), "w") as ssh_config_file:
			ssh_config_file.write(self._vagrant_call("ssh-config").output)
		self.ssh_config = os.path.join(self.vm_directory, ".vagrant_ssh")

	def _invalidate_ssh_config(self):
		self.ssh_config = None


class VagrantException(Exception):
	def __init__(self, vagrant, message):
		self.vagrant = vagrant
		self.message = message

	def __str__(self):
		return "%s: (%s, %s)" % (self.message, self.vagrant.box_name, self.vagrant.vm_directory)
