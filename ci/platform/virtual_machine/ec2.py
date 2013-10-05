import imp
import logging
import pipes
import re
import socket
import sys
import time

import boto.ec2
import boto.exception
import eventlet, eventlet.pools

import model_server

from pysh.shell_tools import ShellCommand, ShellChain, ShellAppend, ShellRedirect, ShellOr, ShellAnd, ShellSilent, ShellCapture
from settings.aws import AwsSettings
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine

try:
	ec2metadata = imp.load_source('ec2metadata', '/usr/bin/ec2metadata')
except:
	ec2metadata = None


class Ec2Client(object):
	@classmethod
	def get_client(cls):
		return cls._connect(AwsSettings.aws_access_key_id, AwsSettings.aws_secret_access_key)

	@classmethod
	def validate_credentials(cls, aws_access_key_id, aws_secret_access_key, region=None):
		try:
			cls._connect(aws_access_key_id, aws_secret_access_key, region)
		except:
			return False
		else:
			return True

	@classmethod
	def _connect(cls, aws_access_key_id, aws_secret_access_key, region=None):
		region = region or AwsSettings.region
		if not region and ec2metadata is not None:
			availability_zone = ec2metadata.get('availability-zone')
			region = re.search(
				"(us|sa|eu|ap)-(north|south)?(east|west)?-[0-9]+",
				availability_zone
			).group(0)
		conn = boto.ec2.connect_to_region(region,
			aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)
		if conn:
			return conn
		raise cls.InvalidRegionError(region)


	class InvalidCredentialsFilter(object):
		def filter(self, record):
			message = record.getMessage()
			return message != '401 Unauthorized' and 'AWS was not able to validate the provided access credentials' not in message

	# Never log invalid credentials errors
	logging.getLogger('boto').addFilter(InvalidCredentialsFilter())


	class InvalidRegionError(Exception):
		pass


class Ec2Broker(object):
	def __init__(self):
		self._ec2_client_pool = eventlet.pools.Pool(create=Ec2Client.get_client)
		self._last_request_time = 0
		self._instances = []
		self._updater_greenlet = None

	def connection(self):
		return self._ec2_client_pool.item()

	def _update_instances(self):
		if time.time() - self._last_request_time < 5:
			return  # The information is new enough

		if self._updater_greenlet is None:
			self._updater_greenlet = eventlet.spawn(self._update_instance_info)

		self._updater_greenlet.wait()
		self._updater_greenlet = None

	def _update_instance_info(self):
		with self.connection() as conn:
			self._instances = map(lambda reservation: reservation.instances[0], conn.get_all_instances())
		self._last_request_time = time.time()

	def get_all_instances(self):
		self._update_instances()
		return self._instances

	def get_instance_by_id(self, instance_id):
		self._update_instances()
		instances = filter(lambda instance: instance.id == instance_id, self._instances)
		if instances:
			return instances[0]
		return None


CloudBroker = Ec2Broker()


@Logged()
class Ec2Vm(VirtualMachine):
	CloudClient = CloudBroker.connection
	Settings = AwsSettings

	def __init__(self, vm_id, instance, vm_username):
		super(Ec2Vm, self).__init__(vm_id, instance, vm_username)
		self.store_vm_info()

	@classmethod
	def from_id_or_construct(cls, vm_id, name=None, ami=None, instance_type=None, vm_username=None):
		return cls.from_vm_id(vm_id) or cls.construct(vm_id, name, ami, instance_type, vm_username)

	@classmethod
	def construct(cls, vm_id, name=None, ami=None, instance_type=None, vm_username=None):
		if not name:
			master_name = None
			if ec2metadata:
				try:
					master_name = CloudBroker.get_instance_by_id(ec2metadata.get('instance-id')).tags['Name']
				except:
					pass
			if not master_name:
				master_name = socket.gethostname()
			name = "koality-worker:%s (%s)" % (vm_id, master_name)
		if not ami:
			ami = cls.get_active_image()
		if not instance_type:
			instance_type = AwsSettings.instance_type

		vm_username = vm_username or AwsSettings.vm_username

		security_group = AwsSettings.security_group
		cls._validate_security_group(security_group)

		with cls.CloudClient() as ec2_client:
			instance = ec2_client.run_instances(ami.id, instance_type=instance_type,
				security_groups=[security_group],
				user_data=cls._default_user_data(vm_username),
				block_device_map=cls._block_device_mapping(ami)).instances[0]

		cls._name_instance(instance, name)
		return Ec2Vm(vm_id, instance, vm_username)

	@classmethod
	def _block_device_mapping(cls, ami):
		bdm_dict = ami.block_device_mapping.copy()
		if '/dev/sda' in bdm_dict.keys():
			root_drive_name = '/dev/sda'
		elif '/dev/sda1' in bdm_dict.keys():
			root_drive_name = '/dev/sda1'
		else:
			root_drive_name = sorted(bdm_dict.keys())[0]  # this is just a wild guess, as ami.root_device_name is wrong

		bdm_dict[root_drive_name].size = max(bdm_dict[root_drive_name].size, AwsSettings.root_drive_size)
		bdm = boto.ec2.blockdevicemapping.BlockDeviceMapping()
		for key, value in bdm_dict.iteritems():
			bdm[key] = value
		return bdm

	@classmethod
	def _default_user_data(cls, vm_username):
		'''This utilizes Ubuntu cloud-init, which runs this script at "rc.local-like" time
		when it finishes first boot.
		This will fail if we use an image which doesn't utilitize EC2 user_data
		'''
		koality_config = '#!/bin/sh\n%s' % ShellChain(
			ShellCommand('useradd --create-home -s /bin/bash %s' % vm_username),
			ShellCommand('mkdir ~%s/.ssh' % vm_username),
			ShellAppend('echo %s' % pipes.quote(PubkeyRegistrar().get_ssh_pubkey()), '~%s/.ssh/authorized_keys' % vm_username),
			ShellCommand('chown -R %s:%s ~%s/.ssh' % (vm_username, vm_username, vm_username)),
			ShellOr(
				ShellCommand("grep '#includedir /etc/sudoers.d' /etc/sudoers"),
				ShellAppend('echo #includedir /etc/sudoers.d', '/etc/sudoers')
			),
			ShellCommand('mkdir /etc/sudoers.d'),
			ShellRedirect("echo 'Defaults !requiretty\n%s ALL=(ALL) NOPASSWD: ALL'" % vm_username, '/etc/sudoers.d/koality-%s' % vm_username),
			ShellCommand('chmod 0440 /etc/sudoers.d/koality-%s' % vm_username)
		)
		given_user_data = AwsSettings.user_data
		if given_user_data:
			generate_user_data = ShellAnd(
				ShellSilent(
					ShellAnd(
						ShellCommand('koalitydata=%s' % ShellCapture('mktemp')),
						ShellRedirect('echo %s' % pipes.quote(koality_config), '$koalitydata'),
						ShellCommand('userdata=%s' % ShellCapture('mktemp')),
						ShellRedirect('echo %s' % pipes.quote(given_user_data), '$userdata')
					)
				),
				ShellCommand('write-mime-multipart "$koalitydata" "$userdata"'),
				ShellSilent('rm $koalitydata'),
				ShellSilent('rm $userdata')
			)
			results = cls._call('bash -c %s' % pipes.quote(str(generate_user_data)))
			if results.returncode == 0:
				return results.output
		return koality_config

	@classmethod
	def _validate_security_group(cls, security_group):
		cidr_ip = '%s/32' % socket.gethostbyname(socket.gethostname())
		if ec2metadata:
			own_security_groups = ec2metadata.get('security-groups').split('\n')
		else:
			own_security_groups = []
		group = cls._get_or_create_security_group(security_group)
		for rule in group.rules:
			if (rule.ip_protocol == 'tcp' and
				int(rule.from_port) <= 22 and
				int(rule.to_port) >= 22):
				for grant in rule.grants:
					if grant.cidr_ip == cidr_ip:
						cls.logger.debug('Found ssh authorization rule on security group "%s" for ip "%s"' % (security_group, cidr_ip))
						return
					elif grant.name in own_security_groups:
						cls.logger.debug('Found ssh authorization rule on security group "%s" for security group "%s"' % (security_group, grant.name))
						return
		cls.logger.info('Adding ssh authorization rule to security group "%s" for ip "%s"' % (security_group, cidr_ip))
		group.authorize('tcp', '22', '22', cidr_ip, None)
		return group

	@classmethod
	def _get_or_create_security_group(cls, security_group):
		with cls.CloudClient() as ec2_client:
			groups = filter(lambda group: group.name == security_group, ec2_client.get_all_security_groups())
			if groups:
				cls.logger.debug('Found existing security group "%s"' % security_group)
				group = groups[0]
			else:
				cls.logger.info('Creating new security group "%s"' % security_group)
				group = ec2_client.create_security_group(security_group, 'Auto-generated Koality verification security group')
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
	def _from_instance_id(cls, vm_id, instance_id, vm_username):
		try:
			instance = CloudBroker.get_instance_by_id(instance_id)
			vm = Ec2Vm(vm_id, instance, vm_username)
			if vm.instance.state == 'stopping' or vm.instance.state == 'stopped':
				cls.logger.warn("Found VM %s in %s state" % (vm, vm.instance.state))
				vm.delete()
				return None
			elif vm.instance.state == 'shutting-down' or vm.instance.state == 'terminated':
				return None
			elif vm.instance.state not in ('running', 'pending'):
				cls.logger.critical("Found VM %s in unexpected %s state" % (vm, vm.instance.state))
				vm.delete()
				return None
			return vm
		except:
			return None

	@classmethod
	def _name_instance(cls, instance, name):
		#  Wait until EC2 recognizes that the instance exists
		while True:
			if CloudBroker.get_instance_by_id(instance.id):
				break
			eventlet.sleep(2)
		while not 'Name' in instance.tags:
			failures = 0
			try:
				instance.add_tag('Name', name or '')
				eventlet.sleep(2)
				instance = CloudBroker.get_instance_by_id(instance.id)
			except:
				failures += 1
				if failures > 20:
					raise
				eventlet.sleep(2)  # Sometimes EC2 doesn't recognize that an instance exists yet

	def wait_until_ready(self):
		def handle_error(exc_info=None):
			self.logger.warn("VM %s in error state while waiting for startup" % self, exc_info=exc_info)
			self.rebuild()

		try:
			self.instance = CloudBroker.get_instance_by_id(self.instance.id)
			while not self.instance.state == 'running':
				eventlet.sleep(3)
				self.instance = CloudBroker.get_instance_by_id(self.instance.id)
				if self.instance.state in ['stopped', 'terminated']:
					handle_error()
			for remaining_attempts in reversed(range(40)):
				if remaining_attempts <= 2:
					self.logger.info("Checking VM %s for ssh access, %s attempts remaining" % (self, remaining_attempts))
				if self.ssh_call("true", timeout=10).returncode == 0:
					return
				eventlet.sleep(3)
				self.instance = CloudBroker.get_instance_by_id(self.instance.id)
		except:
			handle_error(sys.exc_info())
		else:
			# Failed to ssh into machine, try again
			self.logger.warn("Unable to ssh into VM %s" % self)
			self.rebuild()

	def store_vm_info(self):
		super(Ec2Vm, self).store_vm_info()
		with model_server.rpc_connect("debug_instances", "create") as debug_create_rpc:
			debug_create_rpc.create_vm_in_db("Ec2Vm", self.instance.id, self.vm_id, self.vm_username)

	def ssh_args(self):
		options = {
			'LogLevel': 'error',
			'StrictHostKeyChecking': 'no',
			'UserKnownHostsFile': '/dev/null',
			'ServerAliveInterval': '20'
		}
		return self.SshArgs(self.vm_username, self.instance.private_ip_address, options=options)

	def reboot(self, force=False):
		self.instance.reboot()

	@classmethod
	def _get_default_base_image(cls):
		with cls.CloudClient() as ec2_client:
			return ec2_client.get_all_images(
				owners=['600991114254'],  # must be changed if our ec2 info changes
				filters={
					'name': 'koality_verification_precise_0.4', # to be changed
					'state': 'available'
				})[0]

	@classmethod
	def get_base_image(cls):
		image_id = AwsSettings.vm_image_id
		if image_id:
			try:
				with cls.CloudClient() as ec2_client:
					return ec2_client.get_image(image_id)
			except:
				cls.logger.exception('Invalid image id specified, using default instead')
		return cls._get_default_base_image()

	@classmethod
	def get_available_base_images(cls):
		with cls.CloudClient() as ec2_client:
			own_images = ec2_client.get_all_images(owners=['self'])
		own_base_images = filter(lambda image: cls.get_snapshot_version(image) is None, own_images)
		return [cls._get_default_base_image()] + sorted(own_base_images, key=lambda image: image.name)

	@classmethod
	def get_snapshots(cls, base_image):
		with cls.CloudClient() as ec2_client:
			return ec2_client.get_all_images(filters={
					'name': cls.format_snapshot_name(base_image, '*'),
					'state': 'available'
				})

	@classmethod
	def get_image_id(cls, image):
		return image.id

	@classmethod
	def get_image_name(cls, image):
		return image.name

	def create_image(self, name, description=None):
		with self.CloudClient() as ec2_client:
			return ec2_client.create_image(self.instance.id, name, description)

	def rebuild(self):
		ami = self.get_active_image()
		instance_type = self.instance.instance_type
		self.delete()
		instance_name = self.instance.tags.get('Name', '')

		security_group = AwsSettings.security_group
		self._validate_security_group(security_group)

		with self.CloudClient() as ec2_client:
			self.instance = ec2_client.run_instances(ami.id, instance_type=instance_type,
				security_groups=[security_group],
				user_data=self._default_user_data(self.vm_username),
				block_device_map=self._block_device_mapping(ami)).instances[0]

		self._name_instance(self.instance, instance_name)

		self.store_vm_info()
		self.wait_until_ready()

	def delete(self):
		if 'Name' in self.instance.tags:
			instance_ids = map(lambda instance: instance.id, filter(lambda instance: instance.tags.get('Name') == self.instance.tags['Name'], CloudBroker.get_all_instances()))
			self._safe_terminate(instance_ids)
		else:
			self._safe_terminate([self.instance.id])
		self.remove_vm_info()
		super(Ec2Vm, self).delete()

	def _safe_terminate(self, instance_ids):
		try:
			with self.CloudClient() as ec2_client:
				ec2_client.terminate_instances(instance_ids)
		except:
			self.logger.info("Failed to terminate instances %s" % instance_ids, exc_info=True)


class SecurityGroups(object):
	@classmethod
	def get_security_group_names(cls):
		try:
			with CloudBroker.connection() as ec2_client:
				existing_groups = map(lambda group: group.name, ec2_client.get_all_security_groups())
		except:
			existing_groups = []
		existing_groups_plus_selected = list(set(existing_groups).union([str(AwsSettings.security_group), str(AwsSettings._default_security_group)]))
		return sorted(existing_groups_plus_selected)


class InstanceTypes(object):
	ordered_types = ['m1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge',
			'm3.xlarge', 'm3.2xlarge', 'c1.medium', 'c1.xlarge', 'hi1.4xlarge', 'hs1.8xlarge']

	@classmethod
	def set_largest_instance_type(cls, largest_instance_type):
		current_instance_type = AwsSettings.instance_type
		AwsSettings.largest_instance_type = largest_instance_type

		if current_instance_type not in cls.get_allowed_instance_types():
			AwsSettings.instance_type = largest_instance_type

	@classmethod
	def get_allowed_instance_types(cls):
		largest_instance_type = AwsSettings.largest_instance_type
		if largest_instance_type in cls.ordered_types:
			return cls.ordered_types[:cls.ordered_types.index(largest_instance_type) + 1]
		else:
			return cls.ordered_types
