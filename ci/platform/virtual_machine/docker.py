import pipes

from util import greenlets
from util.log import Logged
from settings.docker import DockerSettings
from streaming_executor import CommandResults
from virtual_machine import VirtualMachine


@Logged()
class DockerVm(VirtualMachine):
	class ContainerInstance(object):
		def __init__(self, container_id):
			self.id = container_id

	def __init__(self, vm_id):
		username = DockerSettings.container_username
		container_repository = DockerSettings.container_repository
		container_tag = DockerSettings.container_tag

		self.container_image = container_repository + ':' + container_tag if container_tag else container_repository
		self.container_id = self._create_container(self.container_image, username)
		super(DockerVm, self).__init__(vm_id, DockerVm.ContainerInstance(self.container_id), username)

	def _create_container(self, container_image, container_username):
		results = self.call('docker run -u %s -i -a stdin %s /bin/bash' % (pipes.quote(container_username), pipes.quote(container_image)))
		if results.returncode != 0:
			raise Exception("Failed to construct docker instance: %r" % (results,))
		container_id = results.output.strip()
		return container_id

	def wait_until_ready(self):
		pass

	def _ssh_call(self, command, output_handler=None, timeout=None):
		docker_command = 'echo %s | docker start -i -a %s' % (pipes.quote(str(command)), pipes.quote(self.container_id))
		results = self.call('bash -c %s' % pipes.quote(docker_command), output_handler=output_handler, timeout=timeout)
		if results.returncode == 0:
			wait_results = self.call('docker wait %s' % self.container_id)
			if wait_results.returncode != 0:
				returncode = wait_results.returncode
			else:
				try:
					returncode = int(wait_results.output.strip())
				except:
					returncode = 255
			return CommandResults(returncode, results.output)
		return results

	def delete(self):
		return self.call('docker rm %s' % self.container_id)

	def rebuild(self):
		self.delete()
		self.container_id = self._create_container(self.container_image, self.vm_username)
		self.instance = DockerVm.ContainerInstance(self.container_id)

	def __repr__(self):
		return '%s(%r@%r, %s)' % (type(self).__name__, self.vm_username, self.container_image, self.container_id)
