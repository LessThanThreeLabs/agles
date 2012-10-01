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

	def init(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("init", self.box_name, stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def up(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("up", stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def destroy(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("destroy", "-f", stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def provision(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("provision", stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def ssh_call(self, command, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("ssh", "-c", command, stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def sandbox_on(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("sandbox", "on", stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def sandbox_off(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("sandbox", "off", stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def sandbox_rollback(self, stdout_handler=None, stderr_handler=None):
		return self._vagrant_call("sandbox", "rollback", stdout_handler=stdout_handler, stderr_handler=stderr_handler)

	def _vagrant_call(self, *args, **kwargs):
		command = ["vagrant"] + list(args)
		process = Popen(command, stdout=PIPE, stderr=PIPE, cwd=self.vm_directory,
				env=self.vagrant_env)
		stdout_lines = list()
		stderr_lines = list()
		stdout_handler = kwargs.get("stdout_handler")
		stderr_handler = kwargs.get("stderr_handler")
		while True:
			process.poll()
			line = self._handle_stream(process.stdout, stdout_lines, stdout_handler)
			eline = self._handle_stream(process.stderr, stderr_lines, stderr_handler)
			if (line == "" and eline == "" and process.returncode != None):
				break
		line, eline = process.communicate()
		stdout_lines.append(line)
		stderr_lines.append(eline)
		stdout = "\n".join(stdout_lines)
		stderr = "\n".join(stderr_lines)
		returncode = process.returncode
		return VagrantResults(returncode, stdout, stderr)

	def _handle_stream(self, stream, line_list, line_handler):
		line = stream.readline()
		if line:
			line = line.rstrip()
			line_list.append(line)
			if line_handler:
				line_handler(line)
		return line

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
