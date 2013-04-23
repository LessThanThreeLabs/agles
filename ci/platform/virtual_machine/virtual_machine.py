import os
import uuid

import yaml

from shared.constants import VerificationUser
from streaming_executor import StreamingExecutor
from util import greenlets
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar


@Logged()
class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_directory):
		self.vm_directory = vm_directory

	def provision(self, private_key, output_handler=None):
		raise NotImplementedError()

	def export(self, export_prefix, files, output_handler=None):
		raise NotImplementedError("Currently only supported for EC2 VMs")

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

	def remote_checkout(self, repo_name, git_url, ref, output_handler=None):
		assert isinstance(ref, str)

		def _remote_fetch():
			host_url = git_url[:git_url.find(":")]
			command = ' && '.join([
				'(mv /repositories/cached/%s source > /dev/null 2>&1 || git init source)' % repo_name,
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null 2>&1' % host_url,  # first, bypass the yes/no prompt
				'cd source',
				'git fetch %s %s -n --depth 1' % (git_url, ref),
				'git checkout FETCH_HEAD'])
			results = self.ssh_call(command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out ref %s from %s, results: %s" % (ref, git_url, results), exc_info=True)
			return results
		return self._ssh_authorized(_remote_fetch, output_handler)

	def remote_clone(self, git_url, output_handler=None):
		def _remote_clone():
			host_url = git_url[:git_url.find(":")]
			command = ' && '.join([
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null 2>&1' % host_url,  # first, bypass the yes/no prompt
				'git clone %s source' % git_url])
			results = self.ssh_call(command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to clone %s, results: %s" % (git_url, results), exc_info=True)
			return results
		return self._ssh_authorized(_remote_clone, output_handler)

	def _ssh_authorized(self, authorized_command, output_handler=None):
		generate_key = "mkdir ~/.ssh; yes | ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
		pubkey_results = self.ssh_call("(%s) > /dev/null 2>&1; cat .ssh/id_rsa.pub" % generate_key, timeout=20)
		if pubkey_results.returncode != 0:
			if output_handler:
				output_handler.append({1: "Failed to connect to the testing instance. Please try again."})
			self.logger.error("Failed to set up ssh on vm at %s, results: %s" % (self.vm_directory, pubkey_results))
			return pubkey_results
		pubkey = pubkey_results.output
		alias = '__vm_' + str(uuid.uuid1())
		PubkeyRegistrar().register_pubkey(VerificationUser.id, alias, pubkey)
		try:
			return authorized_command()
		finally:
			PubkeyRegistrar().unregister_pubkey(VerificationUser.id, alias)

	def cache_repository(self, repo_name, output_handler=None):
		return self.ssh_call('mv source /repositories/cached/%s' % repo_name, output_handler)

	@classmethod
	def get_newest_image(cls):
		images = cls.get_all_images()
		return max(images, key=cls.get_image_version)  # get image with greatest version

	@classmethod
	def get_newest_global_image(cls):
		images = cls.get_all_images()
		return max(filter(lambda image: cls.get_image_version(image)[1] == -1, images), key=lambda image: cls.get_image_version(image)[0])

	@classmethod
	def get_all_images(cls):
		raise NotImplementedError()

	@classmethod
	def get_image_version(cls, image):
		name_parts = image.name.split('_')
		try:
			major_version, minor_version = float(name_parts[-2]), float(name_parts[-1])
		except (IndexError, ValueError):
			major_version, minor_version = float(name_parts[-1]), -1
		return major_version, minor_version
