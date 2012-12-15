# vagrant.py - Defines a python object wrapper around the vagrant command line interface

"""An interface for Vagrant over the command line.
"""

import collections
import json
import os
import re

from subprocess import Popen, PIPE, STDOUT

import eventlet

from eventlet.green import select
from util import greenlets


class Vagrant(object):
	"""A wrapper for a Vagrant virtual machine"""
	def __init__(self, vm_directory, box_name):
		self.vm_directory = vm_directory
		self.box_name = box_name
		self.vagrant_env = self._get_vagrant_env()
		self.ssh_config = None

	def get_vm_directory(self):
		return self.vm_directory

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

	def provision(self, output_handler=None):
		return self._vagrant_call("provision", output_handler=output_handler)

	def ssh_call(self, command, output_handler=None):
		if not self.ssh_config:
			self._generate_ssh_config()
		return self._call(["ssh", "default", "-q", "-F", self.ssh_config, command], output_handler=output_handler)

	def vbox_call(self, command, output_handler=None):
		vbox_id = self._get_vbox_id()
		return self._vagrant_call("VBoxManage", "guestcontrol", vbox_id, "exec",
			"--username", "vagrant", "--password", "vagrant",
			"--wait-stdout", "--wait-stderr",
			*command.split())

	def sandbox_on(self, output_handler=None):
		return self._vagrant_call("sandbox", "on", output_handler=output_handler)

	def sandbox_off(self, output_handler=None):
		return self._vagrant_call("sandbox", "off", output_handler=output_handler)

	def sandbox_rollback(self, output_handler=None):
		return self._vagrant_call("sandbox", "rollback", output_handler=output_handler)

	def _vagrant_call(self, *args, **kwargs):
		command = ["vagrant"] + list(args)
		return self._call(command, **kwargs)

	def _call(self, command, output_handler=None, **kwargs):
		process = Popen(command, stdout=PIPE, stderr=STDOUT, cwd=self.vm_directory,
				env=self.vagrant_env)

		output_greenlet = eventlet.spawn(self._handle_stream, process.stdout, output_handler)
		output_lines = output_greenlet.wait()

		output = "\n".join(output_lines)
		returncode = process.poll()
		return VagrantResults(returncode, output)

	def _handle_stream(self, stream, line_handler):
		lines = list()
		while True:
			select.select([stream], [], [])
			line = stream.readline()
			if line == "":
				break
			line = line.rstrip()
			lines.append(line)
			if line_handler:
				line_handler.append(len(lines), line)
		return lines

	def _get_vagrant_env(self):
		vagrant_env = os.environ.copy()
		return vagrant_env

	def _get_vbox_id(self):
		with open(os.path.join(self.vm_directory, ".vagrant")) as json_file:
			return json.load(json_file)["active"]["default"]

	def _generate_ssh_config(self):
		with open(os.path.join(self.vm_directory, ".vagrant_ssh"), "w") as ssh_config_file:
			ssh_config_file.write(self._vagrant_call("ssh-config").output)
		self.ssh_config = os.path.join(self.vm_directory, ".vagrant_ssh")

	def _invalidate_ssh_config(self):
		self.ssh_config = None


VagrantResults = collections.namedtuple(
	"VagrantResults", ["returncode", "output"])
