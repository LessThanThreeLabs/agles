import collections
import os
import uuid

from subprocess import Popen, PIPE, STDOUT

import eventlet

from eventlet.green import select
from shared.constants import VerificationUser
from util import greenlets
from verification.shared.pubkey_registrar import PubkeyRegistrar


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

	def remote_checkout(self, git_url, refs, output_handler=None):
		host_url = git_url[:git_url.find(":")]
		self.ssh_call("mkdir ~/.ssh; ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa")
		pubkey = self.ssh_call("cat .ssh/id_rsa.pub").output
		alias = str(uuid.uuid1()) + "_box"
		PubkeyRegistrar().register_pubkey(VerificationUser.id, alias, pubkey)
		try:
			command = "ssh -q -oStrictHostKeyChecking=no %s true" % host_url  # first, bypass the yes/no prompt
			command = command + "&& git clone %s source" % git_url
			command = command + "&& cd source"
			command = command + "&& git fetch origin %s" % refs[0]
			command = command + "&& git checkout FETCH_HEAD"
			for ref in refs[1:]:
				command = command + "&& git fetch origin %s" % ref
				command = command + "&& git merge FETCH_HEAD"
			results = self.ssh_call(command, output_handler)
		finally:
			PubkeyRegistrar().unregister_pubkey(VerificationUser.id, alias)
		return results

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
