import pipes
import tempfile

from util import greenlets

import eventlet

from database.engine import ConnectionFactory
from pysh.shell_tools import ShellAnd, ShellCommand, ShellPipe, ShellAdvertised, ShellOr, ShellSilent, ShellChain, ShellRedirect, ShellIf, ShellNot, ShellTest, ShellSudo
from provisioner import Provisioner
from streaming_executor import StreamingExecutor, CommandResults
from util.log import Logged


@Logged()
class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_id, instance, vm_username, redis_connection=None):
		self.vm_id = vm_id
		self.instance = instance
		self.vm_username = vm_username
		self._redis_conn = redis_connection or ConnectionFactory.get_redis_connection('virtual_machine')

	def provision(self, repo_name, environment, language_config, setup_config, output_handler=None):
		try:
			provisioner = Provisioner(ssh_args=self.ssh_args().to_arg_list())
			return provisioner.provision(
				'~/%s' % repo_name,
				environment=environment,
				language_config=language_config,
				setup_config=setup_config,
				output_handler=output_handler
			)
		except:
			failure_message = 'Failed to provision, could not connect to the testing instance.'
			if output_handler is not None:
				output_handler.append({1: failure_message})
			return CommandResults(1, failure_message)

	def ssh_args(self):
		raise NotImplementedError()

	def scp_call(self, src_fpath, dest_fpath, output_handler=None, timeout=None):
		return self.call(self.ssh_args().to_scp_arg_list(src_fpath, dest_fpath), output_handler=output_handler, timeout=timeout)

	def ssh_call(self, command, output_handler=None, timeout=None):
		try:
			return self.call(self.ssh_args().to_arg_list() + [str(command)], output_handler, timeout=timeout)
		except Exception as e:
			failure_message = 'Failed to connect to the testing instance: %s' % e
			if output_handler is not None:
				output_handler.append({1: failure_message})
			return CommandResults(1, failure_message)

	def delete(self):
		pass

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
		sleep_time = kwargs.get('sleep_time', 5)
		for attempt in xrange(num_attempts):
			kwargs['output_handler'] = output_handler
			results = method(*args, **kwargs)
			if success_check(results):
				return results
			if attempt < num_attempts - 1:
				output_handler = shift_output_handler(output_handler, results.output.count('\n') + 1)
				self.logger.info('Sleeping %d seconds before retrying...' % sleep_time)
				eventlet.sleep(sleep_time)
				sleep_time *= 2
		return results

	def remote_patch(self, repo_name, patch_contents, output_handler=None):
		ansi_bright_cyan = '\033[36;1m'
		ansi_bright_yellow = '\033[33;1m'
		ansi_reset = '\033[0m'

		if patch_contents:
			with tempfile.NamedTemporaryFile(mode='w') as tmp:
				tmp.write(patch_contents.encode('utf8'))
				tmp.flush()
				scp_results = self.scp_call(tmp.name, '.koality_patch')

			if scp_results.returncode != 0:
				self.logger.error('Failed to scp patchfile.\nResults: (%s, %s)' % scp_results)
				if output_handler is not None:
					output_handler.append({1: 'Failed to send patchfile to the remote machine.'})
				return scp_results

			command = ShellAnd(
				ShellCommand('echo %s' % pipes.quote('%sPATCH CONTENTS:%s' % (ansi_bright_cyan, ansi_reset))),
				ShellCommand('echo'),
				ShellCommand('cat ~/.koality_patch'),
				ShellCommand('echo'),
				ShellCommand('echo %s' % pipes.quote('%sPATCHING:%s' % (ansi_bright_cyan, ansi_reset))),
				ShellCommand('echo'),
				ShellAdvertised('cd %s' % repo_name),
				ShellOr(
					ShellAdvertised('git apply ~/.koality_patch'),
					ShellAnd(
						ShellCommand('echo -e %s' % pipes.quote('%sFailed to git apply, attempting standard patching...%s' % (ansi_bright_yellow, ansi_reset))),
						ShellAdvertised('patch -p1 < ~/.koality_patch')
					)
				)
			)
		else:
			command = 'echo %s' % pipes.quote('%sWARNING: No patch contents received.%s' % (ansi_bright_yellow, ansi_reset))

		results = self.ssh_call(command, output_handler)
		if results.returncode != 0:
			self.logger.warn("Failed to apply patch %r\nResults: %s" % (patch_contents, results.output))
		return results

	def configure_ssh(self, private_key, output_handler=None):
		try:
			provisioner = Provisioner(ssh_args=self.ssh_args().to_arg_list())
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
				ShellAdvertised('ssh %s true' % host_url),
				ShellAnd(
					ShellCommand('echo -e %s' % pipes.quote('\\x1b[33;1mFailed to access the master instance. Please check to make sure your security groups are configured correctly.\\x1b[0m')),
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
					ShellSilent(ShellCommand('which git')),
					ShellSudo(ShellAdvertised('apt-get install -y git'))  # TODO (bbland): make this platform agnostic
				),
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
				ShellOr(
					ShellSilent(ShellCommand('which hg')),
					ShellSudo(ShellAdvertised('apt-get install -y mercurial'))  # TODO (bbland): make this platform agnostic
				),
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
						ShellCommand('cd %s' % repo_name),
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
	def get_active_image(cls):
		base_image = cls.get_base_image()
		snapshots = cls.get_snapshots(base_image)
		if snapshots:
			return max(snapshots, key=cls.get_snapshot_version)
		return base_image

	@classmethod
	def get_base_image(cls):
		raise NotImplementedError()

	@classmethod
	def get_available_base_images(cls):
		raise NotImplementedError()

	@classmethod
	def get_snapshots(cls, base_image):
		raise NotImplementedError()

	@classmethod
	def get_image_id(cls, image):
		raise NotImplementedError()

	@classmethod
	def get_image_name(cls, image):
		raise NotImplementedError()

	@classmethod
	def serialize_image(cls, image):
		return {
			'id': cls.get_image_id(image),
			'name': cls.get_image_name(image)
		}

	@classmethod
	def serialize_images(cls, images):
		return map(cls.serialize_image, images)

	@classmethod
	def format_snapshot_name(cls, base_image, snapshot_version):
		return 'koality-snapshot-(%s)-v%s' % (cls.get_image_name(base_image), snapshot_version)

	@classmethod
	def get_snapshot_version(cls, image):
		image_name = cls.get_image_name(image)
		if image_name.startswith('koality-snapshot-'):
			try:
				return int(image_name[image_name.rfind('v')])
			except:
				pass
		return None

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

		def to_scp_arg_list(self, src_fpath, dest_fpath):
			src_fpath = pipes.quote(src_fpath)
			dest_fpath = pipes.quote(dest_fpath)
			return ['scp'] + map(lambda option: '-o%s=%s' % option, self.options.iteritems()) + ['-P', str(self.port), src_fpath, '%s@%s:%s' % (self.username, self.hostname, dest_fpath)]
