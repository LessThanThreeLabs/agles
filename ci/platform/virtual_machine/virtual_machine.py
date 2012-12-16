import collections
import os

from subprocess import Popen, PIPE, STDOUT

import eventlet

from eventlet.green import select
from util import greenlets


class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_directory):
		self.vm_directory = vm_directory

	def provision(self, role, output_handler=None):
		raise NotImplementedError()

	def ssh_call(self, command, output_handler=None):
		raise NotImplementedError()

	def call(self, command, output_handler=None, env={}, **kwargs):
		env = dict(os.environ.copy(), **env)
		process = Popen(command, stdout=PIPE, stderr=STDOUT, cwd=self.vm_directory,
				env=env)

		output_greenlet = eventlet.spawn(self._handle_stream, process.stdout, output_handler)
		output_lines = output_greenlet.wait()

		output = "\n".join(output_lines)
		returncode = process.poll()
		return CommandResults(returncode, output)

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


CommandResults = collections.namedtuple(
	"CommandResults", ["returncode", "output"])
