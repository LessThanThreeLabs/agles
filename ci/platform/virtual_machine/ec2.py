import os
import pipes
import socket

import boto.ec2
import eventlet
import yaml

from settings.aws import AwsSettings
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


class Ec2Client(object):
	@classmethod
	def get_client(cls):
		region = AwsSettings.region or Ec2Vm._call(
			['sh', '-c', 'ec2metadata --availability-zone | grep -Po "(us|sa|eu|ap)-(north|south)?(east|west)?-[0-9]+"']
		).output
		return boto.ec2.connect_to_region(region,
			**AwsSettings.credentials())


@Logged()
class Ec2Vm(VirtualMachine):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"

	def __init__(self, vm_directory, instance, vm_username=VM_USERNAME):
		super(Ec2Vm, self).__init__(vm_directory)
		self.instance = instance
		self.vm_username = vm_username
		self.write_vm_info()

	@classmethod
	def from_directory_or_construct(cls, vm_directory, name=None, ami_image_id=None, instance_type=None, vm_username=VM_USERNAME):
		return cls.from_directory(vm_directory) or cls.construct(vm_directory, name, ami_image_id, instance_type, vm_username)

	@classmethod
	def construct(cls, vm_directory, name=None, ami_image_id=None, instance_type=None, vm_username=VM_USERNAME):
		if not name:
			name = "koality:%s:%s" % (socket.gethostname(), os.path.basename(os.path.abspath(vm_directory)))
		if not ami_image_id:
			ami_image_id = cls.get_newest_image().id
		if not instance_type:
			instance_type = AwsSettings.instance_type

		security_group = AwsSettings.security_group
		cls._validate_security_group(security_group)

		instance = Ec2Client.get_client().run_instances(ami_image_id, instance_type=instance_type,
			security_groups=[security_group],
			user_data=cls._default_user_data(vm_username)).instances[0]
		cls._name_instance(instance, name)
		return Ec2Vm(vm_directory, instance)

	@classmethod
	def _default_user_data(cls, vm_username=VM_USERNAME):
		'''This utilizes Ubuntu cloud-init, which runs this script at "rc.local-like" time
		when it finishes first boot.
		This will fail if we use an image which doesn't utilitize EC2 user_data
		'''
		return '\n'.join(("#!/bin/sh",
			"mkdir /home/%s/.ssh" % vm_username,
			"echo '%s' >> /home/%s/.ssh/authorized_keys" % (PubkeyRegistrar().get_ssh_pubkey(), vm_username),
			"chown -R %s:%s /home/%s/.ssh" % (vm_username, vm_username, vm_username)))

	@classmethod
	def _validate_security_group(cls, security_group):
		group = cls._get_or_create_security_group(security_group)
		for rule in group.rules:
			if (rule.ip_protocol == 'tcp' and
				rule.from_port == '22' and
				rule.to_port == '22'):
				for grant in rule.grants:
					if grant.cidr_ip == '0.0.0.0/0':
						cls.logger.debug('Found ssh authorization rule on security group "%s"' % security_group)
						return
		cls.logger.info('Adding ssh authorization rule to security group "%s"' % security_group)
		group.authorize('tcp', '22', '22', '0.0.0.0/0', None)

	@classmethod
	def _get_or_create_security_group(cls, security_group):
		ec2_client = Ec2Client.get_client()
		groups = filter(lambda group: group.name == security_group, ec2_client.get_all_security_groups())
		if groups:
			cls.logger.debug('Found existing security_group "%s"' % security_group)
			group = groups[0]
		else:
			cls.logger.info('Creating new security group "%s"' % security_group)
			group = ec2_client.create_security_group(security_group, "Auto-generated Koality verification security group")
		return group

	@classmethod
	def from_directory(cls, vm_directory):
		try:
			with open(os.path.join(vm_directory, Ec2Vm.VM_INFO_FILE)) as vm_info_file:
				config = yaml.safe_load(vm_info_file.read())
				instance_id = config['instance_id']
				vm_username = config['username']
		except:
			return None
		else:
			return cls.from_id(vm_directory, instance_id, vm_username)

	@classmethod
	def from_id(cls, vm_directory, instance_id, vm_username=VM_USERNAME):
		try:
			client = Ec2Client.get_client()
			vm = Ec2Vm(vm_directory, client.get_all_instances(instance_id)[0].instances[0], vm_username)
			if vm.instance.state == 'stopping' or vm.instance.state == 'stopped':
				cls.logger.warn("Found VM (%s, %s) in %s state" % (vm_directory, vm.instance.state, instance_id))
				vm.delete()
				return None
			elif vm.instance.state == 'shutting-down' or vm.instance.state == 'terminated':
				return None
			elif vm.instance.state == 'running' and vm.ssh_call("ls source").returncode == 0:  # VM hasn't been recycled
				vm.delete()
				return None
			elif vm.instance.state not in ('running', 'pending'):
				cls.logger.critical("Found VM (%s, %s) in unexpected %s state" % (vm_directory, instance_id, vm.instance.state))
				vm.delete()
				return None
			return vm
		except:
			return None

	@classmethod
	def _name_instance(cls, instance, name):
		ec2_client = Ec2Client.get_client()
		#  Wait until EC2 recognizes that the instance exists
		while True:
			if instance.id in map(lambda res: res.instances[0].id, ec2_client.get_all_instances()):
				break
			eventlet.sleep(2)
			instance.update()
		while not 'Name' in instance.tags:
			try:
				instance.add_tag('Name', name)
				instance.update()
			except:
				eventlet.sleep(1)  # Sometimes EC2 doesn't recognize that an instance exists yet

	def wait_until_ready(self):
		self.instance.update()
		while not self.instance.state == 'running':
			eventlet.sleep(3)
			self.instance.update()
			if self.instance.state == 'terminated' or self.instance.state == 'stopped':
				self.logger.warn("VM (%s, %s) in error state while waiting for startup" % (self.vm_directory, self.instance.id))
				self.rebuild()
		for remaining_attempts in range(24, 0, -1):
			if remaining_attempts <= 3:
				self.logger.info("Checking VM (%s, %s) for ssh access, %s attempts remaining" % (self.vm_directory, self.instance.id, remaining_attempts))
			if self.ssh_call("true").returncode == 0:
				return
			eventlet.sleep(3)
		# Failed to ssh into machine, try again
		self.logger.warn("Unable to ssh into VM (%s, %s)" % (self.vm_directory, self.instance.id))
		self.rebuild()

	def provision(self, private_key, output_handler=None):
		return self.ssh_call("PYTHONUNBUFFERED=true koality-provision '%s'" % private_key,
			timeout=3600, output_handler=output_handler)

	def export(self, export_prefix, files, output_handler=None):
		return self.ssh_call("koality-s3-export %s %s %s %s %s" % (
			pipes.quote(AwsSettings.aws_access_key_id),
			pipes.quote(AwsSettings.aws_secret_access_key),
			pipes.quote(AwsSettings.s3_bucket_name),
			pipes.quote(export_prefix),
			' '.join([pipes.quote(f) for f in files])),
			output_handler=output_handler
		)

	def ssh_call(self, command, output_handler=None, timeout=None):
		login = "%s@%s" % (self.vm_username, self.instance.ip_address)
		return self.call(["ssh", "-q", "-oStrictHostKeyChecking=no", login, command], timeout=timeout, output_handler=output_handler)

	def reboot(self, force=False):
		self.instance.reboot()

	@classmethod
	def get_all_images(cls):
		return Ec2Client.get_client().get_all_images(
			filters={
				'name': AwsSettings.vm_image_name_prefix + '*',
				'state': 'available'
			}
		)

	def create_image(self, name, description=None):
		return Ec2Client.get_client().create_image(self.instance.id, name, description)

	def rebuild(self, ami_image_id=None):
		if not ami_image_id:
			ami_image_id = self.get_newest_image().id
		instance_type = self.instance.instance_type
		self.delete()
		instance_name = self.instance.tags.get('Name')
		self.instance = Ec2Client.get_client().run_instances(ami_image_id, instance_type=instance_type, user_data=self._default_user_data(self.vm_username)).instances[0]
		self._name_instance(self.instance, instance_name)

		self.write_vm_info()
		self.wait_until_ready()

	def delete(self):
		if 'Name' in self.instance.tags:
			instances = [reservation.instances[0] for reservation in Ec2Client.get_client().get_all_instances(
				filters={'tag:Name': self.instance.tags['Name']})]
			for instance in instances:  # Clean up rogue VMs
				self._safe_terminate(instance)
		else:
			self._safe_terminate(self.instance)
		try:
			os.remove(os.path.join(self.vm_directory, Ec2Vm.VM_INFO_FILE))
		except:
			pass

	def _safe_terminate(self, instance):
		try:
			instance.terminate()
		except:
			self.logger.info("Failed to terminate instance %s" % instance, exc_info=True)
