import uuid

from shared.constants import VerificationUser
from util import greenlets
from util.streaming_executor import StreamingExecutor
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
		return StreamingExecutor.execute(command, output_handler, cwd=self.vm_directory, env=env, **kwargs)

	def remote_checkout(self, git_url, refs, output_handler=None):
		host_url = git_url[:git_url.find(":")]
		self.ssh_call("mkdir ~/.ssh; yes | ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa")
		pubkey = self.ssh_call("cat .ssh/id_rsa.pub").output
		alias = str(uuid.uuid1()) + "_box"
		PubkeyRegistrar().register_pubkey(VerificationUser.id, alias, pubkey)
		try:
			command = "ssh -q -oStrictHostKeyChecking=no %s true > /dev/null" % host_url  # first, bypass the yes/no prompt
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
