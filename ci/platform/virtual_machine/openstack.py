import socket

import eventlet

from libcloud.compute.base import NodeState
from libcloud.compute.providers import get_driver

from settings.libcloud import LibCloudSettings
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


class OpenstackClient(object):
	import platform

	if platform.system() == 'Darwin':
		import libcloud.security
		libcloud.security.VERIFY_SSL_CERT_STRICT = False

	@classmethod
	def get_client(cls):
		credentials = LibCloudSettings.extra_credentials
		credentials['key'] = LibCloudSettings.key
		credentials['secret'] = LibCloudSettings.secret
		return cls.connect(LibCloudSettings.cloud_provider, credentials)

	@classmethod
	def validate_credentials(cls, cloud_provider, credentials):
		try:
			cls.connect(cloud_provider, credentials).list_nodes()
		except:
			return False
		else:
			return True

	@classmethod
	def connect(cls, cloud_provider, credentials):
		return get_driver(cloud_provider)(**credentials)


@Logged()
class OpenstackVm(VirtualMachine):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"

	CloudClient = OpenstackClient.get_client

	def __init__(self, vm_id, instance, vm_username=VM_USERNAME):
		super(OpenstackVm, self).__init__(vm_id)
		self.instance = instance
		self.vm_username = vm_username
		self.store_vm_info()

	@classmethod
	def from_id_or_construct(cls, vm_id, name=None, image_id=None, instance_type=None, vm_username=VM_USERNAME):
		return cls.from_vm_id(vm_id) or cls.construct(vm_id, name, image_id, instance_type, vm_username)

	@classmethod
	def construct(cls, vm_id, name=None, image_id=None, instance_type=None, vm_username=VM_USERNAME):
		if not name:
			name = "koality:%s:%s" % (socket.gethostname(), vm_id)
		if image_id:
			image = filter(lambda image: image.id == image_id, cls.get_all_images())[0]
		else:
			image = cls.get_newest_image()
		instance_type = instance_type or LibCloudSettings.instance_type
		size = filter(lambda size: size.id == instance_type, cls.CloudClient().list_sizes())[0]

		instance = cls.CloudClient().create_node(name=name, image=image, size=size,
			ex_userdata=cls._default_user_data(vm_username))
		return cls(vm_id, instance)

	@classmethod
	def _default_user_data(cls, vm_username=VM_USERNAME):
		'''This utilizes Ubuntu cloud-init, which runs this script at "rc.local-like" time
		when it finishes first boot.
		This will fail if we use an image which doesn't utilitize EC2 user_data
		'''
		return '\n'.join(("#!/bin/sh",
			"adduser %s --home /home/%s --shell /bin/bash --disabled-password --gecos ''" % (vm_username, vm_username),
			"mkdir /home/%s/.ssh" % vm_username,
			"echo '%s' >> /home/%s/.ssh/authorized_keys" % (PubkeyRegistrar().get_ssh_pubkey(), vm_username),
			"chown -R %s:%s /home/%s/.ssh" % (vm_username, vm_username, vm_username)))

	@classmethod
	def from_vm_id(cls, vm_id):
		try:
			vm_info = cls.load_vm_info(vm_id)
		except:
			return None
		else:
			return cls._from_instance_id(vm_id, vm_info['instance_id'], vm_info['username'])

	@classmethod
	def _from_instance_id(cls, vm_id, instance_id, vm_username=VM_USERNAME):
		try:
			client = cls.CloudClient()
			instance = filter(lambda instance: instance.id == instance_id, client.list_nodes())[0]
			vm = cls(vm_id, instance, vm_username)
			if vm.instance.state == NodeState.REBOOTING:
				cls.logger.warn("Found VM (%s, %s) in REBOOTING state" % (vm_id, vm.instance.state, instance_id))
				vm.delete()
				return None
			elif vm.instance.state == NodeState.TERMINATED:
				return None
			elif vm.instance.state == NodeState.RUNNING and vm.ssh_call("ls source").returncode == 0:  # VM hasn't been recycled
				vm.delete()
				return None
			elif vm.instance.state not in (NodeState.RUNNING, NodeState.PENDING):
				cls.logger.critical("Found VM (%s, %s) in unexpected %s state.\nState map: %s" % (vm_id, instance_id, vm.instance.state, client.NODE_STATE_MAP))
				vm.delete()
				return None
			return vm
		except:
			return None

	def wait_until_ready(self):
		instance, ip = self.instance.driver.wait_until_running([self.instance])[0]
		self.instance = instance
		for remaining_attempts in range(24, 0, -1):
			if remaining_attempts <= 3:
				self.logger.info("Checking VM (%s, %s) for ssh access, %s attempts remaining" % (self.vm_id, self.instance.id, remaining_attempts))
			if self.ssh_call("true").returncode == 0:
				return
			eventlet.sleep(3)
		# Failed to ssh into machine, try again
		self.logger.warn("Unable to ssh into VM (%s, %s)" % (self.vm_id, self.instance.id))
		self.rebuild()

	def provision(self, private_key, output_handler=None):
		return self.ssh_call("PYTHONUNBUFFERED=true koality-provision '%s'" % private_key,
			timeout=3600, output_handler=output_handler)

	def ssh_call(self, command, output_handler=None, timeout=None):
		login = "%s@%s" % (self.vm_username, self.instance.public_ips[-1])
		return self.call(["ssh", "-q", "-oStrictHostKeyChecking=no", login, command], timeout=timeout, output_handler=output_handler)

	def reboot(self, force=False):
		self.instance.reboot()

	@classmethod
	def get_all_images(cls):
		return filter(lambda image: LibCloudSettings.vm_image_name_prefix in image.name, cls.CloudClient().list_images())

	def create_image(self, name, description=None):
		self.instance.driver.ex_save_image(self.instance, name, metadata={'description': description})

	def rebuild(self, image_id=None):
		if image_id:
			image = filter(lambda image: image.id == image_id, self.get_all_images())[0]
		else:
			image = self.get_newest_image()
		size = self.instance.size
		if size is None:
			if 'flavorId' in self.instance.extra:
				flavorId = self.instance.extra['flavorId']
				size = filter(lambda size: size.id == flavorId, self.instance.driver.list_sizes())[0]

		instance_name = self.instance.name

		self.delete()
		driver = self.instance.driver
		old_instance = self.instance
		instance_id = old_instance.id
		while old_instance is not None and old_instance.state != NodeState.TERMINATED:
			instances = filter(lambda instance: instance.id == instance_id, driver.list_nodes())
			old_instance = instances[0] if instances else None

		for attempt in xrange(5):
			try:
				self.instance = driver.create_node(name=instance_name, image=image, size=size,
					ex_userdata=self._default_user_data(self.vm_username))
			except:
				if attempt < 4:
					eventlet.sleep(3)
				else:
					raise
			else:
				break

		self.store_vm_info()
		self.wait_until_ready()

	def delete(self):
		if self.instance.name:
			instances = filter(lambda instance: instance.name == self.instance.name, self.instance.driver.list_nodes())
			for instance in instances:  # Clean up rogue VMs
				self._safe_terminate(instance)
		else:
			self._safe_terminate(self.instance)
		self.remove_vm_info()

	def _safe_terminate(self, instance):
		try:
			instance.destroy()
		except:
			self.logger.info("Failed to terminate instance %s" % instance, exc_info=True)


class InstanceTypes(object):
	CloudClient = OpenstackClient.get_client

	@classmethod
	def set_largest_instance_type(cls, largest_instance_type):
		current_instance_type = LibCloudSettings.instance_type
		LibCloudSettings.largest_instance_type = largest_instance_type

		if current_instance_type not in cls.get_allowed_instance_types():
			LibCloudSettings.instance_type = largest_instance_type

	@classmethod
	def get_allowed_instance_types(cls):
		largest_instance_type = LibCloudSettings.largest_instance_type
		ordered_types = map(lambda size: size.id, sorted(cls.CloudClient().list_sizes(), key=lambda size: size.ram))
		if largest_instance_type in ordered_types:
			return ordered_types[:ordered_types.index(largest_instance_type) + 1]
		else:
			return ordered_types
