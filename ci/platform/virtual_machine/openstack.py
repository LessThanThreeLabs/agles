import pipes
import platform
import socket

import eventlet

from libcloud.compute.base import NodeState
from libcloud.compute.providers import get_driver

from settings.libcloud import LibCloudSettings
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


class OpenstackClient(object):
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
	VM_USERNAME = 'lt3'

	CloudClient = OpenstackClient.get_client
	Settings = LibCloudSettings

	def __init__(self, vm_id, instance, vm_username=VM_USERNAME):
		super(OpenstackVm, self).__init__(vm_id, instance, vm_username)
		self.store_vm_info()

	@classmethod
	def from_id_or_construct(cls, vm_id, name=None, image_id=None, instance_type=None, vm_username=VM_USERNAME):
		return cls.from_vm_id(vm_id) or cls.construct(vm_id, name, image_id, instance_type, vm_username)

	@classmethod
	def construct(cls, vm_id, name=None, image_id=None, instance_type=None, vm_username=VM_USERNAME):
		if not name:
			name = "koality:%s:%s" % (socket.gethostname(), vm_id)
		if image_id:
			image = filter(lambda image: str(image.id) == str(image_id), cls.get_all_images())[0]
		else:
			image = cls.get_newest_image()
		instance_type = instance_type or cls.Settings.instance_type
		size = cls._get_instance_size(instance_type)

		security_group_name = cls.Settings.security_group
		security_group = cls._validate_security_group(security_group_name)

		cls._delete_instances_with_name(name)

		instance = cls.CloudClient().create_node(name=name, image=image, size=size,
			ex_userdata=cls._default_user_data(vm_username),
			ex_security_groups=[security_group])
		return cls(vm_id, instance, vm_username)

	@classmethod
	def _delete_instances_with_name(cls, instance_name):
		'''Openstack gets mad if you try to create two instances with the same name, so delete any offenders first'''
		while True:
			instances_with_name = filter(lambda instance: instance.name == instance_name, cls.CloudClient().list_nodes())
			if not instances_with_name:
				return
			for instance in instances_with_name:
				cls._safe_terminate(instance)
			eventlet.sleep(3)

	@classmethod
	def _default_user_data(cls, vm_username=VM_USERNAME):
		'''This utilizes Ubuntu cloud-init, which runs this script at "rc.local-like" time
		when it finishes first boot.
		This will fail if we use an image which doesn't utilitize EC2 user_data
		'''
		return '\n'.join(("#!/bin/sh",
			"useradd --create-home %s" % vm_username,
			"mkdir ~%s/.ssh" % vm_username,
			"echo '%s' >> ~%s/.ssh/authorized_keys" % (PubkeyRegistrar().get_ssh_pubkey(), vm_username),
			"chown -R %s:%s ~%s/.ssh" % (vm_username, vm_username, vm_username)))

	@classmethod
	def _validate_security_group(cls, security_group):
		cidr_ip = '%s/32' % socket.gethostbyname(socket.gethostname())
		# TODO: make this more generalized, but ec2metadata is usually provided for openstack clouds
		if platform.system() == 'Darwin':
			own_security_groups = []
		else:
			own_security_groups = cls._call(['ec2metadata', '--security-groups']).output.split('\n')
		group = cls._get_or_create_security_group(security_group)
		for rule in group.rules:
			if (rule.ip_protocol == 'tcp' and
				int(rule.from_port) <= 22 and
				int(rule.to_port) >= 22):
				if rule.ip_range == cidr_ip:
					cls.logger.debug('Found ssh authorization rule on security group "%s" for ip "%s"' % (security_group, cidr_ip))
					return group
				elif rule.group and rule.group['name'] in own_security_groups and rule.group['tenant_id'] == group.tenant_id:
					cls.logger.debug('Found ssh authorization rule on security group "%s" for security group "%s"' % (security_group, rule.group['name']))
					return group
		cls.logger.info('Adding ssh authorization rule to security group "%s" for ip "%s"' % (security_group, cidr_ip))
		cls.CloudClient().ex_create_security_group_rule(group, 'tcp', 22, 22, cidr_ip, None)
		return group

	@classmethod
	def _get_or_create_security_group(cls, security_group):
		client = cls.CloudClient()
		groups = filter(lambda group: group.name == security_group, client.ex_list_security_groups())
		if groups:
			cls.logger.debug('Found existing security group "%s"' % security_group)
			group = groups[0]
		else:
			cls.logger.info('Creating new security group "%s"' % security_group)
			group = client.ex_create_security_group(security_group, 'Auto-generated Koality verification security group')
		return group

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
			instance = filter(lambda instance: str(instance.id) == str(instance_id), client.list_nodes())[0]
			vm = cls(vm_id, instance, vm_username)
			if vm.instance.state == NodeState.REBOOTING:
				cls.logger.warn("Found VM %s in REBOOTING state" % (vm, instance_id))
				vm.delete()
				return None
			elif vm.instance.state == NodeState.TERMINATED:
				return None
			elif vm.instance.state not in (NodeState.RUNNING, NodeState.PENDING):
				cls.logger.critical("Found VM %s in unexpected %s state.\nState map: %s" % (vm, vm.instance.state, client.NODE_STATE_MAP))
				vm.delete()
				return None
			return vm
		except:
			return None

	@classmethod
	def _get_instance_size(cls, instance_type, matching_attribute='id'):
		return filter(lambda size: getattr(size, matching_attribute) == instance_type, cls.CloudClient().list_sizes())[0]

	def wait_until_ready(self):
		try:
			instance, ip = self.instance.driver.wait_until_running([self.instance], timeout=240, ssh_interface='private_ips')[0]
		except:
			self.logger.warn("VM %s in error state while waiting for startup" % self, exc_info=True)
			self.rebuild()
		else:
			self.instance = instance
			for remaining_attempts in reversed(range(20)):
				if remaining_attempts <= 2:
					self.logger.info("Checking VM %s for ssh access, %s attempts remaining" % (self, remaining_attempts))
				if self.ssh_call("true", timeout=10).returncode == 0:
					return
				eventlet.sleep(3)
			# Failed to ssh into machine, try again
			self.logger.warn("Unable to ssh into VM %s" % self)
			self.rebuild()

	def provision(self, repo_name, private_key, output_handler=None):
		return self.ssh_call("PYTHONUNBUFFERED=true koality-provision %s %s" % (pipes.quote(repo_name), pipes.quote(private_key)),
			timeout=3600, output_handler=output_handler)

	def ssh_args(self):
		options = {
			'LogLevel': 'error',
			'StrictHostKeyChecking': 'no',
			'UserKnownHostsFile': '/dev/null',
			'ServerAliveInterval': '20'
		}
		return self.SshArgs(self.vm_username, self.instance.private_ips[-1], options=options)

	def reboot(self, force=False):
		self.instance.reboot()

	@classmethod
	def get_all_images(cls):
		vm_image_name_search_term = '%s_%s_%s' % (LibCloudSettings.vm_image_name_prefix, LibCloudSettings.vm_image_name_suffix, LibCloudSettings.vm_image_name_version)
		return filter(lambda image: vm_image_name_search_term in image.name, cls.CloudClient().list_images())

	def create_image(self, name, description=None):
		self.instance.driver.ex_save_image(self.instance, name, metadata={'description': description})

	def rebuild(self):
		image = self.get_newest_image()
		size = self.instance.size
		if size is None:
			if 'flavorId' in self.instance.extra:
				flavorId = self.instance.extra['flavorId']
				size = self._get_instance_size(flavorId, 'id')

		instance_name = self.instance.name

		security_group_name = self.Settings.security_group
		security_group = self._validate_security_group(security_group_name)

		self.delete()

		# Use a new connection to avoid connections becoming stale and unauthorized
		client = self.CloudClient()
		old_instance = self.instance
		instance_id = old_instance.id
		while old_instance is not None and old_instance.state != NodeState.TERMINATED:
			instances = filter(lambda instance: instance.id == instance_id, client.list_nodes())
			old_instance = instances[0] if instances else None

		for attempt in xrange(5):
			try:
				self.instance = client.create_node(name=instance_name, image=image, size=size,
					ex_userdata=self._default_user_data(self.vm_username),
					ex_security_groups=[security_group])
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
			self._delete_instances_with_name(self.instance.name)
		else:
			self._safe_terminate(self.instance)
		self.remove_vm_info()
		super(OpenstackVm, self).delete()

	@classmethod
	def _safe_terminate(cls, instance):
		try:
			instance.destroy()
		except:
			cls.logger.info("Failed to terminate instance %s" % instance, exc_info=True)


class SecurityGroups(object):
	CloudClient = OpenstackClient.get_client

	@classmethod
	def get_security_group_names(cls):
		try:
			existing_groups = map(lambda group: group.name, cls.CloudClient().ex_list_security_groups())
		except:
			existing_groups = []
		existing_groups_plus_selected = list(set(existing_groups).union([str(LibCloudSettings.security_group), str(LibCloudSettings._default_security_group)]))
		return sorted(existing_groups_plus_selected)


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
		try:
			ordered_types = map(lambda size: size.id, sorted(cls.CloudClient().list_sizes(), key=lambda size: size.ram))
		except:
			ordered_types = []
		if largest_instance_type in ordered_types:
			return ordered_types[:ordered_types.index(largest_instance_type) + 1]
		else:
			return ordered_types
