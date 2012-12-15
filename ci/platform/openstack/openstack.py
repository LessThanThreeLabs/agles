import os

from subprocess import Popen, PIPE, STDOUT

import eventlet
import novaclient.client
import yaml

from eventlet.green import select
from settings.openstack import credentials
from util import greenlets
from verification.shared.pubkey_registrar import PubkeyRegistrar


class OpenstackClient(object):
	@classmethod
	def get_client(cls):
		return novaclient.client.Client(*credentials[0], **credentials[1])


class OpenstackVm(object):
	VM_INFO_FILE = ".virtualmachine"
	VM_USERNAME = "lt3"

	def __init__(self, vm_directory, server, vm_username=VM_USERNAME):
		self.vm_directory = vm_directory
		self.server = server
		self.nova_client = OpenstackClient.get_client()
		self.vm_username = vm_username
		self._write_vm_info()

	@classmethod
	def from_directory_or_construct(cls, vm_directory, name, image, flavor=None, vm_username=VM_USERNAME):
		return cls.from_directory(vm_directory) or cls.construct(vm_directory, name, image, flavor, vm_username)

	@classmethod
	def construct(cls, vm_directory, name, image, flavor=None, vm_username=VM_USERNAME):
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
		return OpenstackVm(vm_directory, OpenstackClient.get_client().servers.get(vm_id), vm_username=vm_username)

	def _write_vm_info(self):
		config = yaml.dump({'server_id': self.server.id, 'username': self.vm_username})
		with open(os.path.join(self.vm_directory, OpenstackVm.VM_INFO_FILE), "w") as vm_info_file:
			vm_info_file.write(config)

	def wait_until_ready(self):
		while not (self.server.accessIPv4 and self.server.progress == 100):
			eventlet.sleep(0.1)
			self.server = self.nova_client.servers.get(self.server.id)

	def provision(self, role, output_handler=None):
		return self.ssh_call("chef-solo -o role[%s]" % role, output_handler)

	def ssh_call(self, command, output_handler=None):
		login = "%s@%s" % (self.vm_username, self.server.accessIPv4)
		return self._call(["ssh", login, "-q", "-oStrictHostKeyChecking=no", command], output_handler=output_handler)

	def reboot(self, force=False):
		reboot_type = 'REBOOT_HARD' if force else 'REBOOT_SOFT'
		self.server.reboot(reboot_type)

	def delete(self):
		self.server.delete()
		os.remove(os.path.join(self.vm_directory, OpenstackVm.VM_INFO_FILE))

	def save_snapshot(self, image_name):
		image_id = self.server.create_image(image_name)
		return self.nova_client.image.get(image_id)

	def rebuild(self, image):
		self.server.rebuild(image)
		self.wait_until_ready()

	def remote_clone(self, git_url):
		return self.ssh_call("git clone %s source" % git_url)

	def _call(self, command, output_handler=None, **kwargs):
		process = Popen(command, stdout=PIPE, stderr=STDOUT, cwd=self.vm_directory)

		output_greenlet = eventlet.spawn(self._handle_stream, process.stdout, output_handler)
		output_lines = output_greenlet.wait()

		output = "\n".join(output_lines)
		returncode = process.poll()
		return (returncode, output)

	def _handle_stream(self, stream, line_handler):
		lines = list()
		while True:
			select.select([stream], [], [])
			line = stream.readline()
			if line == "":
				break
			line = line.rstrip()
			lines.append(line)
			if line_handler:
				line_handler.append(len(lines), line)
		return lines
