import pipes

import eventlet

from settings.aws import AwsSettings
from shared.constants import KOALITY_EXPORT_PATH
from util.log import Logged
from virtual_machine import VirtualMachine


@Logged()
class DockerVm(VirtualMachine):
	CONTAINER_USERNAME = 'lt3'
	CONTAINER_NAME = 'koality/verification'

	def __init__(self, virtual_machine, container_username=CONTAINER_USERNAME):
		super(DockerVm, self).__init__(virtual_machine.vm_id, virtual_machine.instance, virtual_machine.vm_username)
		self.virtual_machine = virtual_machine
		self.container_username = container_username
		self.container_id = None

	def wait_until_ready(self):
		self.virtual_machine.wait_until_ready()
		if self.container_id is None:
			self._containerize_vm()

	def provision(self, repo_name, private_key, output_handler=None):
		return self.ssh_call("PYTHONUNBUFFERED=true koality-provision %s %s" % (pipes.quote(repo_name), pipes.quote(private_key)),
			timeout=3600, output_handler=output_handler)

	def export(self, export_prefix, filepath, output_handler=None):
		return self.ssh_call("cd %s && koality-export s3 %s %s %s %s %s; rm -rf %s" % (
			KOALITY_EXPORT_PATH,
			pipes.quote(AwsSettings.aws_access_key_id),
			pipes.quote(AwsSettings.aws_secret_access_key),
			pipes.quote(AwsSettings.s3_bucket_name),
			pipes.quote(export_prefix),
			pipes.quote(filepath),
			pipes.quote(filepath)),
			output_handler=output_handler
		)

	def ssh_call(self, command, output_handler=None, timeout=None):
		if self.container_id is None:
			self._containerize_vm()
		ssh_options = '-oLogLevel=error -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null'
		retrieve_ssh_port_command = 'docker port %s 22' % self.container_id
		docker_command = 'ssh %s@localhost %s -p $(%s) %s' % (
			self.container_username, ssh_options, retrieve_ssh_port_command, pipes.quote(command)
		)
		return self.virtual_machine.ssh_call(docker_command, output_handler, timeout)

	def delete(self):
		return self.virtual_machine.delete()

	def rebuild(self):
		self._uncontainerize_vm()
		self._containerize_vm()

	def create_image(self, name, description=None):
		assert name is not None
		assert self.container_id is not None
		if description is None:
			description = ''
		commit_results = self.virtual_machine.ssh_call('docker commit %s -m=%s %s' % (self.container_id, pipes.quote(description), pipes.quote(name)))
		assert commit_results.returncode == 0
		return self.virtual_machine.create_image(name, description)

	def _containerize_vm(self):
		docker_construction_command = '&&'.join((
			'[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa > /dev/null 2>&1',
			'SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub',
			'docker run -d -p 22 %s /init %s "$SSH_PUBLIC_KEY"' % (self.CONTAINER_NAME, self.container_username)
		))
		container_construction_result = self.virtual_machine.ssh_call('bash -c %s' % pipes.quote(docker_construction_command))
		if container_construction_result.returncode != 0:
			error_message = 'Failed to construct a a docker container inside VM %s' % self.virtual_machine
			self.logger.warn(error_message)
			raise Exception(error_message)
		self.container_id = container_construction_result.output.strip()

		for attempt in range(12):
			if self.ssh_call('true', timeout=10).returncode == 0:
				return
			else:
				eventlet.sleep(10)
		try:
			raise Exception('Failed to initialize ssh daemon for container %s' % self)
		finally:
			self._uncontainerize_vm()

	def _uncontainerize_vm(self):
		if self.container_id is not None:
			self.virtual_machine.ssh_call('docker kill %s' % self.container_id)
			self.container_id = None

	def __repr__(self):
		return '%s(%r, %r, %s)' % (type(self).__name__, self.virtual_machine, self.container_username, self.container_id)
