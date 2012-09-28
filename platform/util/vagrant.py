# vagrant.py - Defines a python object wrapper around the vagrant command line interface

"""An interface for Vagrant over the command line.
"""

import collections
import os

from subprocess import Popen, PIPE
from time import sleep


class Vagrant(object):
	"""A wrapper for a Vagrant virtual machine"""
	def __init__(self, vm_directory, box_name):
		self.vm_directory = vm_directory
		self.box_name = box_name
		self.vagrant_env = self._get_vagrant_env()

	def init(self):
		return self._vagrant_call("init", self.box_name)

	def up(self):
		return self._vagrant_call("up")

	def destroy(self):
		return self._vagrant_call("destroy", "-f")

	def provision(self):
		return self._vagrant_call("provision")

	def ssh_call(self, command):
		return self._vagrant_call("ssh", "-c", command)

	def sandbox_on(self):
		return self._vagrant_call("sandbox", "on")

	def sandbox_off(self):
		return self._vagrant_call("sandbox", "off")

	def sandbox_rollback(self):
		return self._vagrant_call("sandbox", "rollback")

	def _vagrant_call(self, *args):
		command = ["vagrant"] + list(args)
		process = Popen(command, stdout=PIPE, stderr=PIPE, cwd=self.vm_directory,
				env=self.vagrant_env)
		stdout, stderr = process.communicate()
		returncode = process.returncode
		return VagrantResults(returncode, stdout, stderr)

	def spawn(self):
		self.teardown()
		print "Spawning vm at " + self.vm_directory
		if not os.access(self.vm_directory, os.F_OK):
			os.mkdir(self.vm_directory)

		if self.init().returncode != 0:
			raise Exception("Couldn't initialize vagrant: " + self.vm_directory)
		if self.up().returncode != 0:
			raise Exception("Couldn't start vagrant vm: " + self.vm_directory)
		sleep(1)  # TODO (bbland): decide if this is necessary
		if self.sandbox_on().returncode != 0:
			raise Exception("Couldn't initialize sandbox on vm: " + self.vm_directory)
		print "Launched vm at: " + self.vm_directory

	def teardown(self):
		vagrantfile = os.path.join(self.vm_directory, "Vagrantfile")
		if os.access(vagrantfile, os.F_OK):
			print "Tearing down existing vm at " + self.vm_directory
			if self.destroy().returncode != 0:
				raise Exception("Couldn't tear down existing vm: " + self.vm_directory)
			os.remove(vagrantfile)

	def _get_vagrant_env(self):
		vagrant_env = os.environ.copy()
		vagrant_env["AGLES_ROOT"] = os.path.realpath(
				os.path.join(__file__,
						os.path.join("..",
								os.path.join("..",
										".."))))


VagrantResults = collections.namedtuple(
	"VagrantResults", ["returncode", "stdout", "stderr"])
