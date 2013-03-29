import logging
import os
import socket

import eventlet
import novaclient.client
import yaml

from settings.openstack import OpenstackSettings
from verification.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


class OpenstackClient(object):
	@classmethod
	def get_client(cls):
		credentials = OpenstackSettings.credentials()
		return novaclient.client.Client(*credentials[0], **credentials[1])


class OpenstackVm(VirtualMachine):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"
	logger = logging.getLogger("OpenstackVm")

	def __init__(self, vm_directory, instance, vm_username=VM_USERNAME):
		super(OpenstackVm, self).__init__(vm_directory)
		self.instance = instance
		self.vm_username = vm_username
		self.write_vm_info()

	@classmethod
	def from_directory_or_construct(cls, vm_directory, name=None, image=None, flavor=None, vm_username=VM_USERNAME):
		return cls.from_directory(vm_directory) or cls.construct(vm_directory, name, image, flavor, vm_username)

	@classmethod
	def construct(cls, vm_directory, name=None, image=None, flavor=None, vm_username=VM_USERNAME):
		if not name:
			name = "koality:%s:%s" % (socket.gethostname(), os.path.basename(os.path.abspath(vm_directory)))
		if not image:
			image = cls.get_newest_image()
		if not flavor:
			flavor = cls._default_flavor()
		instance = OpenstackClient.get_client().servers.create(name, image, flavor, files=cls._default_files(vm_username))
		return OpenstackVm(vm_directory, instance)

	@classmethod
	def _default_flavor(cls):
		flavors = OpenstackClient.get_client().flavors.findall(ram=2048, vcpus=2)
		for flavor in flavors:
			if 'blimp' in flavor.name:
				return flavor
		return flavors[0]

	@classmethod
	def _default_files(cls, vm_username=VM_USERNAME):
		return {"/home/%s/.ssh/authorized_keys" % vm_username: PubkeyRegistrar().get_ssh_pubkey()}

	@classmethod
	def from_directory(cls, vm_directory):
		try:
			with open(os.path.join(vm_directory, OpenstackVm.VM_INFO_FILE)) as vm_info_file:
				config = yaml.safe_load(vm_info_file.read())
				vm_id = config['instance_id']
				vm_username = config['username']
		except:
			return None
		else:
			return cls.from_id(vm_directory, vm_id, vm_username)

	@classmethod
	def from_id(cls, vm_directory, vm_id, vm_username=VM_USERNAME):
		try:
			vm = OpenstackVm(vm_directory, OpenstackClient.get_client().servers.get(vm_id), vm_username=vm_username)
			if vm.instance.status == 'ERROR':
				OpenstackVm.logger.warn("Found VM (%s, %s) in ERROR state" % (vm_directory, vm_id))
				vm.delete()
				return None
			elif vm.instance.status == 'DELETED':
				return None
			elif vm.instance.status == 'ACTIVE' and vm.ssh_call("ls source").returncode == 0:  # VM hasn't been recycled
				vm.delete()
				return None
			return vm
		except:
			return None

	def wait_until_ready(self):
		while not ('private' in self.instance.addresses and self.instance.status == 'ACTIVE'):
			eventlet.sleep(3)
			self.instance = OpenstackClient.get_client().servers.get(self.instance.id)
			if self.instance.status == 'ERROR':
				OpenstackVm.logger.warn("VM (%s, %s) in error state while waiting for startup" % (self.vm_directory, self.instance.id))
				self.rebuild()
		for remaining_attempts in range(24, 0, -1):
			if remaining_attempts <= 3:
				OpenstackVm.logger.info("Checking VM (%s, %s) for ssh access, %s attempts remaining" % (self.vm_directory, self.instance.id, remaining_attempts))
			if self.ssh_call("true").returncode == 0:
				return
			eventlet.sleep(5)
		# Failed to ssh into machine, try again
		OpenstackVm.logger.warn("Unable to ssh into VM (%s, %s)" % (self.vm_directory, self.instance.id))
		self.rebuild()

	def provision(self, private_key, output_handler=None):
		return self.ssh_call("python -u -c \"from provisioner.provisioner import Provisioner; Provisioner().provision('''%s''')\"" % private_key,
			timeout=3600, output_handler=output_handler)

	def ssh_call(self, command, output_handler=None, timeout=None):
		login = "%s@%s" % (self.vm_username, self.instance.accessIPv4 or self.instance.addresses['private'][0]['addr'])
		return self.call(["ssh", "-q", "-oStrictHostKeyChecking=no", login, command], timeout=timeout, output_handler=output_handler)

	def reboot(self, force=False):
		reboot_type = 'REBOOT_HARD' if force else 'REBOOT_SOFT'
		self.instance.reboot(reboot_type)

	def delete(self):
		for instance in OpenstackClient.get_client().servers.findall(name=self.instance.name):  # Clean up rogue VMs
			try:
				instance.delete()
			except:
				pass
		try:
			os.remove(os.path.join(self.vm_directory, OpenstackVm.VM_INFO_FILE))
		except:
			pass

	def create_image(self, image_name):
		image_id = self.instance.create_image(image_name)
		return OpenstackClient.get_client().images.get(image_id)

	def rebuild(self, image=None):
		if not image:
			image = self.get_newest_image()
		name = self.instance.name
		flavor = self.instance.flavor['id']
		self.delete()
		self.instance = OpenstackClient.get_client().servers.create(name, image, flavor, files=self._default_files(self.vm_username))
		self.write_vm_info()
		self.wait_until_ready()

	@classmethod
	def get_all_images(cls):
		images = OpenstackClient.get_client().images.list()
		return [image for image in images if OpenstackSettings.image_filter(image) and image.status == 'ACTIVE']
