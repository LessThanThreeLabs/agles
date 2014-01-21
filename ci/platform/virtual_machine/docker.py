import pipes

from util import greenlets
from util.log import Logged
from virtual_machine import VirtualMachine


@Logged()
class DockerVm(VirtualMachine):
	CONTAINER_USERNAME = 'root'
	CONTAINER_IMAGE = 'base'

	class ContainerInstance(object):
		def __init__(self, container_id):
			self.id = container_id

	def __init__(self, vm_id, container_username=CONTAINER_USERNAME):
		self.container_id = self._create_container(self.CONTAINER_IMAGE)
		self.container_image = self.CONTAINER_IMAGE
		super(DockerVm, self).__init__(vm_id, DockerVm.ContainerInstance(self.container_id), container_username)

	def _create_container(self, container_image):
		results = self.call('docker run -i -a stdin %s /bin/bash' % pipes.quote(container_image))
		if results.returncode != 0:
			raise Exception("Failed to construct docker instance: %r", (results,))
		container_id = results.output.strip()
		return container_id

	def wait_until_ready(self):
		pass

	def ssh_call(self, command, output_handler=None, timeout=None):
		docker_command = 'echo %s | docker start -i -a %s' % (pipes.quote(command), self.container_id)
		return self.call('bash -c %s' % pipes.quote(docker_command), output_handler=output_handler, timeout=timeout)

	def delete(self):
		return self.call('docker rm %s' % self.container_id)

	def rebuild(self):
		self.delete()
		self.container_id = self._create_container(self.container_image)
		self.instance = DockerVm.ContainerInstance(self.container_id)

	def __repr__(self):
		return '%s(%r@%r, %s)' % (type(self).__name__, self.vm_username, self.container_image, self.container_id)
