# vagrant.py - Defines a python object wrapper around the vagrant command line interface

"""An interface for Vagrant over the command line.
"""

import collections
import os

from subprocess import Popen, PIPE

import eventlet

from eventlet.green import select
from util import greenlets


class Vagrant(object):
	"""A wrapper for a Vagrant virtual machine"""
	def __init__(self, vm_directory, box_name):
		self.vm_directory = vm_directory
		self.box_name = box_name
		self.vagrant_env = self._get_vagrant_env()

	def get_vm_directory(self):
		return self.vm_directory

	def init(self, output_handler=None):
		return self._vagrant_call("init", self.box_name, output_handler=output_handler)

	def up(self, output_handler=None):
		return self._vagrant_call("up", output_handler=output_handler)

	def destroy(self, output_handler=None):
		return self._vagrant_call("destroy", "-f", output_handler=output_handler)

	def provision(self, output_handler=None):
		return self._vagrant_call("provision", output_handler=output_handler)

	def ssh_call(self, command, output_handler=None):
		return self._vagrant_call("ssh", "-c", command, output_handler=output_handler)

	def sandbox_on(self, output_handler=None):
		return self._vagrant_call("sandbox", "on", output_handler=output_handler)

	def sandbox_off(self, output_handler=None):
		return self._vagrant_call("sandbox", "off", output_handler=output_handler)

	def sandbox_rollback(self, output_handler=None):
		return self._vagrant_call("sandbox", "rollback", output_handler=output_handler)

	def _vagrant_call(self, *args, **kwargs):
		command = ["vagrant"] + list(args)
		process = Popen(command, stdout=PIPE, stderr=PIPE, cwd=self.vm_directory,
				env=self.vagrant_env)

		output_handler = kwargs.get("output_handler")

		self._output = list()
		stdout_greenlet = eventlet.spawn(self._handle_stream, process.stdout, output_handler)
		stderr_greenlet = eventlet.spawn(self._handle_stream, process.stderr, output_handler)

		stdout_lines = stdout_greenlet.wait()
		stderr_lines = stderr_greenlet.wait()

		stdout = "\n".join(stdout_lines)
		stderr = "\n".join(stderr_lines)
		returncode = process.poll()
		return VagrantResults(returncode, stdout, stderr)

	def _handle_stream(self, stream, line_handler):
		lines = list()
		while True:
			select.select([stream], [], [])
			line = stream.readline()
			if line == "":
				break
			line = line.rstrip()
			lines.append(line)
			self._output.append(line)
			if line_handler:
				line_handler(len(self._output), line)
		return lines

	def _get_vagrant_env(self):
		vagrant_env = os.environ.copy()
		vagrant_env["AGLES_ROOT"] = os.path.realpath(
				os.path.join(__file__,
						os.path.join("..",
								os.path.join("..",
										os.path.join("..",
											"..")))))
		return vagrant_env


VagrantResults = collections.namedtuple(
	"VagrantResults", ["returncode", "stdout", "stderr"])
