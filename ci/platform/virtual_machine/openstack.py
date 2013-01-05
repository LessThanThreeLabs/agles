import os
import socket
import uuid

import eventlet
import novaclient.client
import yaml

from settings.openstack import credentials
from verification.shared.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


class OpenstackClient(object):
	@classmethod
	def get_client(cls):
		return novaclient.client.Client(*credentials[0], **credentials[1])


class OpenstackVm(VirtualMachine):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"
	VM_IMAGE_NEWEST_PREFIX = "precise64_box_"

	def __init__(self, vm_directory, server, vm_username=VM_USERNAME):
		super(OpenstackVm, self).__init__(vm_directory)
		self.server = server
		self.nova_client = OpenstackClient.get_client()
		self.vm_username = vm_username
		self._write_vm_info()

	@classmethod
	def from_directory_or_construct(cls, vm_directory, name=None, image=None, flavor=None, vm_username=VM_USERNAME):
		return cls.from_directory(vm_directory) or cls.construct(vm_directory, name, image, flavor, vm_username)

	@classmethod
	def construct(cls, vm_directory, name=None, image=None, flavor=None, vm_username=VM_USERNAME):
		if not name:
			name = "vs_%s@%s" % (vm_directory, socket.gethostname())
		if not image:
			image = cls._get_newest_image()
		if not flavor:
			flavor = OpenstackClient.get_client().flavors.find(ram=1024)
		server = OpenstackClient.get_client().servers.create(name, image, flavor, files=cls._default_files(vm_username))
		return OpenstackVm(vm_directory, server)

	@classmethod
	def _default_files(cls, vm_username=VM_USERNAME):
		return {"/home/%s/.ssh/authorized_keys" % vm_username: PubkeyRegistrar().get_ssh_pubkey()}

	@classmethod
	def from_directory(cls, vm_directory):
		try:
			with open(os.path.join(vm_directory, OpenstackVm.VM_INFO_FILE)) as vm_info_file:
				config = yaml.load(vm_info_file.read())
				vm_id = config['server_id']
				vm_username = config['username']
		except:
			return None
		else:
			return cls.from_id(vm_directory, vm_id, vm_username)

	@classmethod
	def from_id(cls, vm_directory, vm_id, vm_username=VM_USERNAME):
		try:
			vm = OpenstackVm(vm_directory, OpenstackClient.get_client().servers.get(vm_id), vm_username=vm_username)
			if vm.server.status == 'ERROR':
				vm.delete()
				return None
			elif vm.server.status == 'DELETED':
				return None
			return vm
		except:
			return None

	def _write_vm_info(self):
		config = yaml.dump({'server_id': self.server.id, 'username': self.vm_username})
		if not os.access(self.vm_directory, os.F_OK):
			os.makedirs(self.vm_directory)
		with open(os.path.join(self.vm_directory, OpenstackVm.VM_INFO_FILE), "w") as vm_info_file:
			vm_info_file.write(config)

	def wait_until_ready(self):
		while not (self.server.accessIPv4 and self.server.status == 'ACTIVE'):
			eventlet.sleep((100 - self.server.progress) / 10.0)  # 0-10 seconds depending on progress
			self.server = self.nova_client.servers.get(self.server.id)

	def provision(self, role, output_handler=None):
		return self.ssh_call("sudo chef-solo -o role[%s]" % role, output_handler)

	def ssh_call(self, command, output_handler=None):
		login = "%s@%s" % (self.vm_username, self.server.accessIPv4)
		return self.call(["ssh", "-q", "-oStrictHostKeyChecking=no", login, command], output_handler=output_handler)

	def reboot(self, force=False):
		reboot_type = 'REBOOT_HARD' if force else 'REBOOT_SOFT'
		self.server.reboot(reboot_type)

	def delete(self):
		self.server.delete()
		os.remove(os.path.join(self.vm_directory, OpenstackVm.VM_INFO_FILE))

	def save_snapshot(self, image_name):
		image_id = self.server.create_image(image_name)
		return self.nova_client.images.get(image_id)

	def rebuild(self, image=None):
		if not image:
			image = self._get_newest_image()
		name = self.server.name
		flavor = self.server.flavor['id']
		self.delete()
		self.server = self.nova_client.servers.create(name, image, flavor, files=self._default_files(self.vm_username))
		self._write_vm_info()
		self.wait_until_ready()

	@classmethod
	def _get_newest_image(cls):
		images = OpenstackClient.get_client().images.list()
		images = [image for image in images if image.name.startswith(cls.VM_IMAGE_NEWEST_PREFIX) and image.status == 'ACTIVE']
		images.sort(key=lambda image: int(image.name[len(cls.VM_IMAGE_NEWEST_PREFIX):]), reverse=True)
		return images[0]
