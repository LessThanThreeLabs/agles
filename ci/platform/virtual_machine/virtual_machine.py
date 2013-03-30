import os
import uuid

import yaml

from shared.constants import VerificationUser
from util import greenlets
from util.streaming_executor import StreamingExecutor
from verification.pubkey_registrar import PubkeyRegistrar


class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_directory):
		self.vm_directory = vm_directory

	def provision(self, private_key, output_handler=None):
		raise NotImplementedError()

	def ssh_call(self, command, output_handler=None, timeout=None):
		raise NotImplementedError()

	@classmethod
	def _call(self, command, output_handler=None, env={}, timeout=None, **kwargs):
		return StreamingExecutor().execute(command, output_handler, env=env, timeout=timeout, **kwargs)

	def call(self, command, output_handler=None, env={}, timeout=None, **kwargs):
		return self._call(command, output_handler, cwd=self.vm_directory, env=env, timeout=timeout, **kwargs)

	def write_vm_info(self):
		config = yaml.safe_dump({'instance_id': self.instance.id, 'username': self.vm_username})
		if not os.access(self.vm_directory, os.F_OK):
			os.makedirs(self.vm_directory)
		with open(os.path.join(self.vm_directory, self.VM_INFO_FILE), "w") as vm_info_file:
			vm_info_file.write(config)

	def remote_checkout(self, git_url, refs, output_handler=None):
		host_url = git_url[:git_url.find(":")]
		generate_key = "mkdir ~/.ssh; yes | ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
		pubkey_results = self.ssh_call("(%s) > /dev/null 2>&1; cat .ssh/id_rsa.pub" % generate_key, timeout=20)
		if pubkey_results.returncode != 0:
			output_handler.append({1: "Failed to connect to the testing instance. Please try again."})
			return pubkey_results
		pubkey = pubkey_results.output
		alias = '__vm_' + str(uuid.uuid1())
		PubkeyRegistrar().register_pubkey(VerificationUser.id, alias, pubkey)
		try:
			command = ' && '.join([
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null' % host_url,  # first, bypass the yes/no prompt
				'git init source',
				'cd source',
				'git fetch %s %s -n --depth 1' % (git_url, refs[0]),
				'git checkout FETCH_HEAD'])
			for ref in refs[1:]:
				command = ' && '.join([
					command,
					'git fetch origin %s' % ref,
					'git merge FETCH_HEAD'])
			results = self.ssh_call(command, output_handler)
		finally:
			PubkeyRegistrar().unregister_pubkey(VerificationUser.id, alias)
		return results

	@classmethod
	def get_newest_image(cls):
		images = cls.get_all_images()
		return max(images, key=cls.get_image_version)  # get image with greatest version

	@classmethod
	def get_all_images(cls):
		raise NotImplementedError()

	@classmethod
	def get_image_version(cls, image):
		name_parts = image.name.split('_')
		try:
			major_version, minor_version = int(name_parts[-2]), int(name_parts[-1])
		except (IndexError, ValueError):
			major_version, minor_version = int(name_parts[-1]), -1
		return major_version, minor_version
