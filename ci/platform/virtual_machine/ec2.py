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
		return boto.ec2.connect_to_region(*AwsSettings.credentials[0], **AwsSettings.credentials[1])


class Ec2Vm(VirtualMachine):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"
	DEFAULT_INSTANCE_TYPE = "m1.small"
	logger = logging.getLogger("Ec2Vm")

	def __init__(self, vm_directory, reservation, vm_username=VM_USERNAME):
		super(Ec2Vm, self).__init__(vm_directory)
		self.reservation = reservation
		self.ec2_client = Ec2Client.get_client()
		self.vm_username = vm_username
		self.write_vm_info()

	@classmethod
	def from_directory_or_construct(cls, vm_directory, name=None, ami_image_id=None, instance_type=None, vm_username=VM_USERNAME):
		return cls.from_directory(vm_directory) or cls.construct(vm_directory, name, ami_image_id, instance_type, vm_username)

	@classmethod
	def construct(cls, vm_directory, name=None, ami_image_id=None, instance_type=None, key_name=None, vm_username=VM_USERNAME):
		if not name:
			name = "%s:%s" % (socket.gethostname(), os.path.basename(os.path.abspath(os.getcwd())))
		if not ami_image_id:
			ami_image_id = cls.get_newest_image()
		if not instance_type:
			instance_type = cls.DEFAULT_INSTANCE_TYPE
		if not key_name:
			key_name = cls._get_default_key()

		reservation = Ec2Client.get_client().run_instances(ami_image_id, instance_type=instance_type, key_name=key_name)
		return Ec2Vm(vm_directory, reservation)

	def wait_until_ready(self):
		instance = self.reservation.instances[0]
		while True:
			eventlet.sleep(3)
			instance.update()
			if instance.state == 'terminated' or instance.state == 'stopped':
				Ec2Vm.logger.warn("VM (%s, %s) in error state while waiting for startup" % (self.vm_directory, instance.id))
				self.rebuild()
		for remaining_attempts in range(24, 0, -1):
			if remaining_attempts <= 3:
				Ec2Vm.logger.info("Checking VM (%s, %s) for ssh access, %s attempts remaining" % (self.vm_directory, instance.id, remaining_attempts))
			if self.ssh_call("true").returncode == 0:
				return
			eventlet.sleep(5)
		# Failed to ssh into machine, try again
		Ec2Vm.logger.warn("Unable to ssh into VM (%s, %s)" % (self.vm_directory, instance.id))
		self.rebuild()

	def provision(self, private_key, output_handler=None):
		return self.ssh_call("python -u -c \"from provisioner.provisioner import Provisioner; Provisioner().provision('''%s''')\"" % private_key,
			timeout=1200, output_handler=output_handler)

	def ssh_call(self, command, output_handler=None, timeout=None):
		login = "%s@%s" % (self.vm_username, self.reservation.accessIPv4 or self.reservation.addresses['private'][0]['addr'])
		return self.call(["ssh", "-q", "-oStrictHostKeyChecking=no", login, command], timeout=timeout, output_handler=output_handler)

	def reboot(self, force=False):
		self.reservation[0].reboot()

	@classmethod
	def get_newest_image(cls):
		images = Ec2Client.get_all_images()
		images = [image for image in images if AwsSettings.image_filter(image)]  # TODO: Verify this doesn't need to check for ACTIVE (seems to be the case)
		return max(images, key=lambda image: str(image)[str(image).rfind('-') + 1:])  # get image with greatest suffix number

	@classmethod
	def get_default_key(cls):
		pass

	def rebuild(self, ami_image_id=None):
		if not ami_image_id:
			ami_image_id = self.get_newest_image()
		instance = self.reservation.instances[0]
		instance_type = instance.instance_type
		key_name = instance.key_name
		self.delete()
		self.reservation = Ec2Client.get_client().run_instances(ami_image_id, instance_type=instance_type, key_name=key_name)

		self.write_vm_info()
		self.wait_until_ready()

	def delete(self):
		for instance in self.ec2_client.reservation:  # Clean up rouge VMs
			try:
				instance.terminate()
			except:
				pass
		try:
			os.remove(os.path.join(self.vm_directory, Ec2Vm.VM_INFO_FILE))
		except:
			pass