import pipes
import uuid

import paramiko

from database.engine import ConnectionFactory
from pysh.shell_tools import ShellAnd, ShellCommand, ShellPipe, ShellAdvertised, ShellOr, ShellSilent, ShellChain, ShellRedirect, ShellIf, ShellNot, ShellTest, ShellSudo
from provisioner import Provisioner
from shared.constants import VerificationUser
from streaming_executor import StreamingExecutor, RemoteStreamingExecutor, CommandResults
from util.log import Logged


@Logged()
class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_id, instance, vm_username, redis_connection=None):
		self.vm_id = vm_id
		self.instance = instance
		self.vm_username = vm_username
		self._redis_conn = redis_connection or ConnectionFactory.get_redis_connection('virtual_machine')
		self._ssh_conn = None

	def provision(self, repo_name, language_config, setup_config, output_handler=None):
		try:
			provisioner = Provisioner(self._ssh_connect())
			return provisioner.provision(
				'~/%s' % repo_name,
				language_config=language_config,
				setup_config=setup_config,
				output_handler=output_handler
			)
		except:
			failure_message = 'Failed to provision, could not connect to the testing instance.'
			if output_handler is not None:
				output_handler.append({1: failure_message})
			return CommandResults(1, failure_message)

	def export(self, export_prefix, file_paths, output_handler=None):
		raise NotImplementedError("Currently only supported for EC2 VMs")

	def ssh_args(self):
		raise NotImplementedError()

	def _ssh_connect(self):
		if not self._ssh_conn or not self._ssh_conn.get_transport():
			ssh_conn = paramiko.SSHClient()
			ssh_conn.set_missing_host_key_policy(paramiko.WarningPolicy())
			ssh_args = self.ssh_args()
			ssh_conn.connect(ssh_args.hostname, ssh_args.port, ssh_args.username)
			self._ssh_conn = ssh_conn
		return self._ssh_conn

	def ssh_call(self, command, output_handler=None, timeout=None):
		try:
			return RemoteStreamingExecutor(self._ssh_connect()).execute(command, output_handler, timeout=timeout)
		except Exception as e:
			failure_message = 'Failed to connect to the testing instance: %s' % e
			if output_handler is not None:
				output_handler.append({1: failure_message})
			return CommandResults(1, failure_message)

	def close_connection(self):
		if self._ssh_conn:
			self._ssh_conn.close()

	def delete(self):
		self.close_connection()

	def rebuild(self):
		raise NotImplementedError()

	@classmethod
	def _call(cls, command, output_handler=None, env={}, timeout=None, **kwargs):
		return StreamingExecutor().execute(command, output_handler, env=env, timeout=timeout, **kwargs)

	def call(self, command, output_handler=None, env={}, timeout=None, **kwargs):
		return self._call(command, output_handler, env=env, timeout=timeout, **kwargs)

	def store_vm_info(self):
		self.store_vm_metadata(instance_id=self.instance.id, username=self.vm_username)

	def remove_vm_info(self):
		try:
			self._redis_conn.delete(self.vm_id)
		except:
			self.logger.info("Failed to remove vm info from redis for vm %s" % self.vm_id)

	def store_vm_metadata(self, **metadata):
		self._redis_conn.hmset(self.vm_id, metadata)

	def get_vm_metadata(self):
		return self._redis_conn.hgetall(self.vm_id)

	def remove_vm_metadata(self, *keys):
		self._redis_conn.hdel(self.vm_id, *keys)

	@classmethod
	def load_vm_info(cls, vm_id):
		redis_conn = ConnectionFactory.get_redis_connection('virtual_machine')
		instance_id, username = redis_conn.hmget(vm_id, ('instance_id', 'username'))
		return {'instance_id': instance_id, 'username': username}

	def _try_multiple_times(self, num_attempts, success_check, method, *args, **kwargs):
		def shift_output_handler(output_handler, line_count_shift):
			if output_handler is None:
				return None

			class ShiftedConsoleAppender(object):
				def append(self, read_lines):
					shifted_lines = dict(map(lambda item: (item[0] + line_count_shift, item[1]), read_lines.iteritems()))
					output_handler.append(shifted_lines)

			return ShiftedConsoleAppender()

		output_handler = kwargs.get('output_handler')
		for x in xrange(num_attempts):
			kwargs['output_handler'] = output_handler
			results = method(*args, **kwargs)
			if success_check(results):
				return results
			output_handler = shift_output_handler(output_handler, results.output.count('\n') + 1)
		return results

	def remote_patch(self, repo_name, patch_contents, output_handler=None):
		ansi_bright_cyan = '\033[36;1m'
		ansi_bright_yellow = '\033[33;1m'
		ansi_reset = '\033[0m'

		if patch_contents:
			command = ShellAnd(
				ShellCommand('echo %s' % pipes.quote('%sPATCH CONTENTS:%s' % (ansi_bright_cyan, ansi_reset))),
				ShellCommand('echo'),
				ShellCommand('echo %s' % pipes.quote(patch_contents)),
				ShellCommand('echo'),
				ShellCommand('echo %s' % pipes.quote('%sPATCHING:%s' % (ansi_bright_cyan, ansi_reset))),
				ShellCommand('echo'),
				ShellAdvertised('cd %s' % repo_name),
				ShellAdvertised('patch -p1 ...', actual_command=ShellPipe('echo %s' % pipes.quote(patch_contents), 'patch -p1'))
			)
		else:
			command = 'echo %s' % pipes.quote('%sWARNING: No patch contents received.%s' % (ansi_bright_yellow, ansi_reset))

		results = self.ssh_call(command, output_handler)
		if results.returncode != 0:
			self.logger.warn("Failed to apply patch %s\nResults: %s" % (patch_contents, results.output))
		return results

	def configure_ssh(self, private_key, output_handler=None):
		try:
			provisioner = Provisioner(self._ssh_connect())
			return provisioner.set_private_key(
				private_key,
				output_handler=output_handler
			)
		except:
			failure_message = 'Failed to provision, could not connect to the testing instance.'
			if output_handler is not None:
				output_handler.append({1: failure_message})
			return CommandResults(1, failure_message)

	def _get_host_access_check_command(self, host_url):
		return ShellAnd(
			ShellCommand('echo Testing ssh connection to master instance...'),
			ShellOr(
				ShellSilent('ssh -oStrictHostKeyChecking=no %s true' % host_url),
				ShellAnd(
					ShellCommand('echo Failed to access the master instance. Please check to make sure your security groups are configured correctly.'),
					ShellCommand('false')
				)
			),
		)

	def remote_checkout(self, repo_name, repo_url, repo_type, ref, output_handler=None):
		def _remote_fetch():
			host_url = repo_url[:repo_url.find(":")]
			command = ShellAnd(
				self._get_host_access_check_command(host_url),
				ShellOr(
					ShellSilent('mv /repositories/cached/%s %s' % (repo_name, repo_name)),
					ShellChain(
						ShellSilent('rm -rf %s' % repo_name),
						ShellAdvertised('git init %s' % repo_name)
					)
				),
				ShellAdvertised('cd %s' % repo_name),
				ShellAdvertised('git fetch %s %s -n --depth 1' % (repo_url, ref)),
				ShellAdvertised('git checkout --force FETCH_HEAD')
			)

			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler=output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out ref %s from %s, results: %s" % (ref, repo_url, results))
			return results

		def _remote_update():
			host_url, _, repo_uri = repo_url.split('://')[1].partition('/')

			get_ref_command = ShellOr(
				ShellAdvertised('hg update --clean %s' % ref),
				ShellAnd(
					ShellCommand('mkdir -p .hg/strip-backup'),
					ShellCommand('echo Downloading bundle file for %s' % ref),
					ShellPipe('ssh -q %s "hg cat-bundle %s %s"' % (host_url, repo_uri, ref), ShellRedirect('base64 -d', '.hg/strip-backup/%s.hg' % ref)),
					ShellAdvertised('hg unbundle .hg/strip-backup/%s.hg' % ref),
					ShellAdvertised('hg update --clean %s' % ref)
				)
			)

			command = ShellAnd(
				self._get_host_access_check_command(host_url),
				ShellIf(
					ShellSilent('mv /repositories/cached/%s %s' % (repo_name, repo_name)),
					ShellAnd(
						ShellAdvertised('cd %s' % repo_name),
						ShellAdvertised('hg pull %s' % repo_url),
						get_ref_command
					),
					ShellChain(
						ShellSilent('rm -rf %s' % repo_name),
						ShellAdvertised('hg clone --uncompressed %s %s' % (repo_url, repo_name)),
						get_ref_command
					)
				),

			)

			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler=output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out bundle %s from %s, results: %s" % (ref, repo_url, results))
			return results

		if repo_type == 'git':
			assert isinstance(ref, (str, unicode))
			return _remote_fetch()
		elif repo_type == 'hg':
			return _remote_update()
		else:
			self.logger.error("Unknown repository type in remote_checkout %s." % repo_type)

	def remote_clone(self, repo_type, repo_name, repo_url, output_handler=None):
		if repo_type == 'git':
			host_url = repo_url[:repo_url.find(":")]
			clone_flags = ''
		elif repo_type == 'hg':
			host_url, _, repo_uri = repo_url.split('://')[1].partition('/')
			clone_flags = '--uncompressed'

		command = ShellAnd(
			ShellOr(
				ShellNot(ShellTest('-e %s' % repo_name)),
				ShellAdvertised('rm -rf %s' % repo_name)
			),
			self._get_host_access_check_command(host_url),
			ShellAdvertised('%s clone %s %s %s' % (repo_type, clone_flags, repo_url, repo_name))
		)
		results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler=output_handler)
		if results.returncode != 0:
			self.logger.error("Failed to clone %s, results: %s" % (repo_url, results))
		return results

	def cache_repository(self, repo_name, output_handler=None):
		command = ShellChain(
			ShellSudo(ShellCommand('chown -R %s:%s %s' % (self.vm_username, self.vm_username, repo_name))),
			ShellOr(
				ShellCommand('mv %s /repositories/cached/%s' % (repo_name, repo_name)),
				ShellCommand('rm -rf %s' % repo_name)
			)
		)
		return self.ssh_call(command, output_handler)

	@classmethod
	def get_newest_image(cls):
		images = cls.get_all_images()
		return max(images, key=cls.get_image_version)  # get image with greatest version

	@classmethod
	def get_newest_global_image(cls):
		images = cls.get_all_images()
		return max(filter(lambda image: cls.get_image_version(image)[1] == -1, images), key=lambda image: cls.get_image_version(image)[0])

	@classmethod
	def get_all_images(cls):
		raise NotImplementedError()

	@classmethod
	def get_image_version(cls, image):
		name_parts = image.name.split('_')
		try:
			major_version, minor_version = VirtualMachine.ImageVersion(name_parts[-2]), VirtualMachine.ImageVersion(name_parts[-1])
		except (IndexError, ValueError):
			try:
				major_version, minor_version = VirtualMachine.ImageVersion(name_parts[-1]), -1
			except:
				major_version, minor_version = -1, -1
		return major_version, minor_version

	def __repr__(self):
		return '%s(%r, %r, %r)' % (type(self).__name__, self.vm_id, self.instance, self.vm_username)

	class SshArgs(object):
		def __init__(self, username, hostname, port=22, options={}):
			self.username = username
			self.hostname = hostname
			self.port = port
			self.options = options

		def to_arg_list(self):
			return ['ssh'] + map(lambda option: '-o%s=%s' % option, self.options.iteritems()) + ['%s@%s' % (self.username, self.hostname), '-p', str(self.port)]


	class ImageVersion(object):
		"""A multiple decimal-place version string (such as 1.0.4)"""
		def __init__(self, string_representation):
			string_representation = str(string_representation)
			self.sub_versions = [int(sub_version) for sub_version in string_representation.split('.')]

		def __eq__(self, other):
			if not isinstance(other, VirtualMachine.ImageVersion):
				try:
					other = VirtualMachine.ImageVersion(other)
				except:
					return False

			return self.sub_versions == other.sub_versions

		def __cmp__(self, other):
			if not isinstance(other, VirtualMachine.ImageVersion):
				other = VirtualMachine.ImageVersion(other)

			for version_index in xrange(len(self.sub_versions)):
				if version_index >= len(other.sub_versions):
					return 1
				else:
					comparison = cmp(self.sub_versions[version_index], other.sub_versions[version_index])
					if comparison != 0:
						return comparison
			if len(self.sub_versions) < len(other.sub_versions):
				return -1
			return 0

		def __add__(self, other):
			if not isinstance(other, VirtualMachine.ImageVersion):
				other = VirtualMachine.ImageVersion(other)

			sub_versions = [0] * max(len(self.sub_versions), len(other.sub_versions))

			for version_index in xrange(len(self.sub_versions)):
				sub_versions[version_index] += self.sub_versions[version_index]

			for version_index in xrange(len(other.sub_versions)):
				sub_versions[version_index] += other.sub_versions[version_index]

			return VirtualMachine.ImageVersion(self._from_sub_versions(sub_versions))

		def __str__(self):
			return self._from_sub_versions(self.sub_versions)

		def __repr__(self):
			return '%s(%s)' % (type(self).__name__, self)

		def _from_sub_versions(self, sub_versions):
			return '.'.join([str(sub_version) for sub_version in sub_versions])
