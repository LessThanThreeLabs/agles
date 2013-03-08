import logging
import os
import socket

import boto.ec2
import eventlet
import yaml

from settings.aws import AwsSettings
from verification.shared.pubkey_registrar import PubkeyRegistrar
from virtual_machine import VirtualMachine


class Ec2Client(object):
	@classmethod
	def get_client(cls):
		return boto.ec2.connect_to_region(AwsSettings.region,
			**AwsSettings.credentials)


class Ec2Vm(VirtualMachine):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"
	DEFAULT_INSTANCE_TYPE = "m1.small"
	logger = logging.getLogger("Ec2Vm")

	def __init__(self, vm_directory, instance, vm_username=VM_USERNAME):
		super(Ec2Vm, self).__init__(vm_directory)
		self.instance = instance
		self.ec2_client = Ec2Client.get_client()
		self.vm_username = vm_username
		self.write_vm_info()

	@classmethod
	def from_directory_or_construct(cls, vm_directory, name=None, ami_image_id=None, instance_type=None, vm_username=VM_USERNAME):
		return cls.from_directory(vm_directory) or cls.construct(vm_directory, name, ami_image_id, instance_type, vm_username)

	@classmethod
	def construct(cls, vm_directory, name=None, ami_image_id=None, instance_type=None, vm_username=VM_USERNAME):
		if not name:
			name = "%s:%s" % (socket.gethostname(), os.path.basename(os.path.abspath(vm_directory)))
		if not ami_image_id:
			ami_image_id = cls.get_newest_image().id
		if not instance_type:
			instance_type = cls.DEFAULT_INSTANCE_TYPE

		instance = Ec2Client.get_client().run_instances(ami_image_id, instance_type=instance_type, user_data=cls._default_user_data(vm_username)).instances[0]
		while not instance.tags.get('Name'):
			instance.add_tag('Name', name)
			eventlet.sleep(2)
			instance.update()
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
			vm = Ec2Vm(vm_directory, Ec2Client.get_client().get_all_instances([instance_id])[0].instances[0], vm_username)
			if vm.instance.state == 'stopping' or vm.instance.state == 'stopped':
				Ec2Vm.logger.warn("Found VM (%s, %s) in ERROR state" % (vm_directory, instance_id))
				vm.delete()
				return None
			elif vm.instance.state == 'shutting-down' or vm.instance.state == 'terminated':
				return None
			elif vm.instance.state == 'running' and vm.ssh_call("ls source").returncode == 0:  # VM hasn't been recycled
				vm.delete()
				return None
			# 'pending' means we should return
			return vm
		except:
			return None

	def wait_until_ready(self):
		while not self.instance.state == 'running':
			eventlet.sleep(3)
			self.instance.update()
			if self.instance.state == 'terminated' or self.instance.state == 'stopped':
				Ec2Vm.logger.warn("VM (%s, %s) in error state while waiting for startup" % (self.vm_directory, self.instance.id))
				self.rebuild()
		for remaining_attempts in range(24, 0, -1):
			if remaining_attempts <= 3:
				Ec2Vm.logger.info("Checking VM (%s, %s) for ssh access, %s attempts remaining" % (self.vm_directory, self.instance.id, remaining_attempts))
			if self.ssh_call("true").returncode == 0:
				return
			eventlet.sleep(5)
		# Failed to ssh into machine, try again
		Ec2Vm.logger.warn("Unable to ssh into VM (%s, %s)" % (self.vm_directory, self.instance.id))
		self.rebuild()

	def provision(self, private_key, output_handler=None):
		return self.ssh_call("python -u -c \"from provisioner.provisioner import Provisioner; Provisioner().provision('''%s''')\"" % private_key,
			timeout=1200, output_handler=output_handler)

	def ssh_call(self, command, output_handler=None, timeout=None):
		login = "%s@%s" % (self.vm_username, self.instance.ip_address)
		return self.call(["ssh", "-q", "-oStrictHostKeyChecking=no", login, command], timeout=timeout, output_handler=output_handler)

	def reboot(self, force=False):
		self.instance.reboot()

	@classmethod
	def get_newest_image(cls):
		images = Ec2Client.get_client().get_all_images(owners=['600991114254'])
		images = [image for image in images if AwsSettings.image_filter(image)]  # TODO: Verify this doesn't need to check for ACTIVE (seems to be the case)
		return max(images, key=lambda image: str(image)[str(image).rfind('_') + 1:])  # get image with greatest suffix number

	def save_snapshot(self, volume_id, description=None):
		return self.ec2_client.create_snapshot(volume_id, description)

	def rebuild(self, ami_image_id=None):
		if not ami_image_id:
			ami_image_id = self.get_newest_image().id
		instance_type = self.instance.instance_type
		self.delete()
		self.instance = Ec2Client.get_client().run_instances(ami_image_id, instance_type=instance_type, user_data=self._default_user_data(self.vm_username)).instances[0]

		self.write_vm_info()
		self.wait_until_ready()

	def delete(self):
		instances = [reservation.instances[0] for reservation in self.ec2_client.get_all_instances(
			filters={'tag:Name': self.instance.tags['Name']})]
		for instance in instances:  # Clean up rogue VMs
			try:
				self.instance.terminate()
			except:
				pass
		try:
			os.remove(os.path.join(self.vm_directory, Ec2Vm.VM_INFO_FILE))
		except:
			pass
