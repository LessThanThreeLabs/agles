import logging
import pipes
import platform
import re
import socket
import sys
import yaml

import boto.ec2
import eventlet

import model_server

from pysh.shell_tools import ShellCommand, ShellChain, ShellAppend, ShellRedirect, ShellOr, ShellAnd, ShellSilent, ShellCapture
from settings.aws import AwsSettings
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


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
		if region is None:
			region = AwsSettings.region or re.search(
				"(us|sa|eu|ap)-(north|south)?(east|west)?-[0-9]+",
				Ec2Vm._call(['ec2metadata', '--availability-zone']).output
			).group(0)
		return boto.ec2.connect_to_region(region,
			aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)

	class InvalidCredentialsFilter(object):
		def filter(self, record):
			message = record.getMessage()
			return message != '401 Unauthorized' and 'AWS was not able to validate the provided access credentials' not in message

	# Never log invalid credentials errors
	logging.getLogger('boto').addFilter(InvalidCredentialsFilter())


@Logged()
class Ec2Vm(VirtualMachine):
	CloudClient = Ec2Client.get_client
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
			try:
				master_instance_id = cls._call(['ec2metadata', '--instance-id']).output.strip()
				master_name = cls.CloudClient().get_all_instances(filters={'instance-id': master_instance_id})[0].instances[0].tags['Name']
			except:
				pass
			if not master_name:
				master_name = socket.gethostname()
			name = "koality-worker:%s (%s)" % (vm_id, master_name)
		if not ami:
			ami = cls.get_newest_image()
		if not instance_type:
			instance_type = AwsSettings.instance_type

		vm_username = vm_username or AwsSettings.vm_username

		security_group = AwsSettings.security_group
		cls._validate_security_group(security_group)

		bdm = ami.block_device_mapping.copy()
		bdm['/dev/sda1'].size = max(bdm['/dev/sda1'].size, AwsSettings.root_drive_size)

		instance = cls.CloudClient().run_instances(ami.id, instance_type=instance_type,
			security_groups=[security_group],
			user_data=cls._default_user_data(vm_username),
			block_device_map=bdm).instances[0]
		cls._name_instance(instance, name)
		return Ec2Vm(vm_id, instance, vm_username)

	@classmethod
	def _default_user_data(cls, vm_username):
		'''This utilizes Ubuntu cloud-init, which runs this script at "rc.local-like" time
		when it finishes first boot.
		This will fail if we use an image which doesn't utilitize EC2 user_data
		'''
		koality_config = '#!/bin/sh\n%s' % ShellChain(
			ShellCommand('useradd --create-home %s' % vm_username),
			ShellCommand('mkdir ~%s/.ssh' % vm_username),
			ShellAppend('echo %s' % pipes.quote(PubkeyRegistrar().get_ssh_pubkey()), '~%s/.ssh/authorized_keys' % vm_username),
			ShellCommand('chown -R %s:%s ~%s/.ssh' % (vm_username, vm_username, vm_username)),
			ShellOr(
				ShellCommand("grep '#includedir /etc/sudoers.d' /etc/sudoers"),
				ShellAppend('echo #includedir /etc/sudoers.d', '/etc/sudoers')
			),
			ShellCommand('mkdir /etc/sudoers.d'),
			ShellRedirect("echo '%s ALL=(ALL) NOPASSWD: ALL'" % vm_username, '/etc/sudoers.d/koality-%s' % vm_username),
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
		if platform.system() == 'Darwin':
			own_security_groups = []
		else:
			own_security_groups = cls._call(['ec2metadata', '--security-groups']).output.split('\n')
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
		ec2_client = cls.CloudClient()
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
			client = cls.CloudClient()
			reservations = client.get_all_instances(filters={'instance-id': instance_id})
			if not reservations:
				return None
			vm = Ec2Vm(vm_id, reservations[0].instances[0], vm_username)
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
		ec2_client = cls.CloudClient()
		#  Wait until EC2 recognizes that the instance exists
		while True:
			if ec2_client.get_all_instances(filters={'instance-id': instance.id}):
				break
			eventlet.sleep(2)
			instance.update()
		while not 'Name' in instance.tags:
			failures = 0
			try:
				instance.add_tag('Name', name or '')
				instance.update()
			except:
				failures += 1
				if failures > 20:
					raise
				eventlet.sleep(1)  # Sometimes EC2 doesn't recognize that an instance exists yet

	def wait_until_ready(self):
		def handle_error(exc_info=None):
			self.logger.warn("VM %s in error state while waiting for startup" % self, exc_info=exc_info)
			self.rebuild()

		try:
			self.instance.update()
			while not self.instance.state == 'running':
				eventlet.sleep(3)
				self.instance.update()
				if self.instance.state in ['stopped', 'terminated']:
					handle_error()
			for remaining_attempts in reversed(range(40)):
				if remaining_attempts <= 2:
					self.logger.info("Checking VM %s for ssh access, %s attempts remaining" % (self, remaining_attempts))
				if self.ssh_call("true", timeout=10).returncode == 0:
					return
				eventlet.sleep(3)
				self.instance.update()
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
	def get_base_image(cls):
		image_id = AwsSettings.vm_image_id
		if image_id:
			try:
				return cls.CloudClient().get_image(image_id)
			except:
				cls.logger.exception('Invalid image id specified, using default instead')
		return cls.CloudClient().get_all_images(filters={
				'name': 'koality_verification_0.3', # to be changed
				'state': 'available',
				'owner': '600991114254'  # must be changed if our ec2 info changes
			})[0]

	@classmethod
	def get_available_base_images(cls):
		return cls.CloudClient().get_all_images(owners=['self'])

	@classmethod
	def get_snapshots(cls, base_image):
		return cls.CloudClient().get_all_images(filters={
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
		return self.CloudClient().create_image(self.instance.id, name, description)

	def rebuild(self):
		ami = self.get_newest_image()
		instance_type = self.instance.instance_type
		self.delete()
		instance_name = self.instance.tags.get('Name', '')

		security_group = AwsSettings.security_group
		self._validate_security_group(security_group)

		bdm = ami.block_device_mapping.copy()
		bdm['/dev/sda1'].size = max(bdm['/dev/sda1'].size, AwsSettings.root_drive_size)

		self.instance = self.CloudClient().run_instances(ami.id, instance_type=instance_type,
			security_groups=[security_group],
			user_data=self._default_user_data(self.vm_username),
			block_device_map=bdm).instances[0]
		self._name_instance(self.instance, instance_name)

		self.store_vm_info()
		self.wait_until_ready()

	def delete(self):
		if 'Name' in self.instance.tags:
			instances = [reservation.instances[0] for reservation in self.CloudClient().get_all_instances(
				filters={'tag:Name': self.instance.tags['Name']})]
			for instance in instances:  # Clean up rogue VMs
				self._safe_terminate(instance)
		else:
			self._safe_terminate(self.instance)
		self.remove_vm_info()
		super(Ec2Vm, self).delete()

	def _safe_terminate(self, instance):
		try:
			instance.terminate()
		except:
			self.logger.info("Failed to terminate instance %s" % instance, exc_info=True)


class SecurityGroups(object):
	@classmethod
	def get_security_group_names(cls):
		try:
			existing_groups = map(lambda group: group.name, Ec2Client.get_client().get_all_security_groups())
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
