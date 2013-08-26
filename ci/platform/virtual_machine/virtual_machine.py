import pipes
import uuid

from database.engine import ConnectionFactory
from shared.constants import VerificationUser
from streaming_executor import StreamingExecutor
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar


@Logged()
class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_id, instance, vm_username, redis_connection=None):
		self.vm_id = vm_id
		self.instance = instance
		self.vm_username = vm_username
		self._redis_conn = redis_connection or ConnectionFactory.get_redis_connection('virtual_machine')

	def provision(self, repo_name, private_key, output_handler=None):
		raise NotImplementedError()

	def export(self, export_prefix, file_paths, output_handler=None):
		raise NotImplementedError("Currently only supported for EC2 VMs")

	def ssh_args(self):
		raise NotImplementedError()

	def ssh_call(self, command, output_handler=None, timeout=None):
		return self.call(self.ssh_args() + [command], timeout=timeout, output_handler=output_handler)

	def delete(self):
		raise NotImplementedError()

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
		for x in xrange(num_attempts):
			results = method(*args, **kwargs)
			if success_check(results):
				return results
		return results

	def remote_patch(self, patch_contents, output_handler=None):
		ansi_bright_cyan = '\033[36;1m'
		ansi_bright_yellow = '\033[33;1m'
		ansi_reset = '\033[0m'

		if patch_contents:
			command = ' && '.join((
				'cd source',
				'echo %s' % pipes.quote('%sPATCH CONTENTS:%s' % (ansi_bright_cyan, ansi_reset)),
				'echo',
				'echo %s' % pipes.quote(patch_contents),
				'echo',
				'echo %s' % pipes.quote('%sPATCHING:%s' % (ansi_bright_cyan, ansi_reset)),
				'echo',
				'echo %s | patch -p1' % pipes.quote(patch_contents)
			))
		else:
			command = 'echo %s' % pipes.quote('%sWARNING: No patch contents received.%s' % (ansi_bright_yellow, ansi_reset))

		results = self.ssh_call(command, output_handler)
		if results.returncode != 0:
			self.logger.warn("Failed to apply patch %s\nResults: " % (pipes.quote(patch_contents), results.output))
		return results

	def remote_checkout(self, repo_name, repo_url, repo_type, ref, output_handler=None):
		def _remote_fetch():
			host_url = repo_url[:repo_url.find(":")]
			command = ' && '.join([
				'(mv /repositories/cached/%s %s > /dev/null 2>&1 || (rm -rf %s > /dev/null 2>&1; git init %s))' % (repo_name, repo_name, repo_name, repo_name),
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null 2>&1' % host_url,  # Bypass the ssh yes/no prompt
				'cd %s' % repo_name,
				'git fetch %s %s -n --depth 1' % (repo_url, ref),
				'git checkout --force FETCH_HEAD'])

			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out ref %s from %s, results: %s" % (ref, repo_url, results))
			return results

		def _remote_update():
			host_url, _, repo_uri = repo_url.split('://')[1].partition('/')
			command = ' && '.join([
				'(mv /repositories/cached/%s source > /dev/null 2>&1 || (rm -rf source > /dev/null 2>&1; hg init source))' % repo_name,
				'cd source',
				'export PYTHONUNBUFFERED=true',
				'hg pull %s' % repo_url,
				'hg update --clean %s 2> /dev/null; r=$?; true' % ref,  # first try to check out the ref
				'if [ "$r" == 0 ]; then exit 0; fi',
				'mkdir -p .hg/strip-backup',  # otherwise try to get the ref from a bundle
				'ssh -oStrictHostKeyChecking=no -q %s \"hg cat-bundle %s %s\" | base64 -d > .hg/strip-backup/%s.hg' % (host_url, repo_uri, ref, ref),
				'hg unbundle .hg/strip-backup/%s.hg' % ref,
				'hg update --clean %s' % ref])

			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out bundle %s from %s, results: %s" % (ref, repo_url, results))
			return results

		if repo_type == 'git':
			assert isinstance(ref, str)
			return self._ssh_authorized(_remote_fetch, output_handler)
		elif repo_type == 'hg':
			return self._ssh_authorized(_remote_update, output_handler)
		else:
			self.logger.error("Unknown repository type in remote_checkout %s." % repo_type)

	def remote_clone(self, repo_type, repo_name, repo_url, output_handler=None):
		def _remote_clone():
			if repo_type == 'git':
				host_url = repo_url[:repo_url.find(":")]
			elif repo_type == 'hg':
				host_url, _, repo_uri = repo_url.split('://')[1].partition('/')
			command = ' && '.join([
				'if [ -e %s ]; then rm -rf %s; fi' % (repo_name, repo_name),
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null 2>&1' % host_url,  # Bypass the ssh yes/no prompt
				'%s clone %s %s' % (repo_type, repo_url, repo_name)])
			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to clone %s, results: %s" % (repo_url, results))
			return results
		return self._ssh_authorized(_remote_clone, output_handler)

	def _ssh_authorized(self, authorized_command, output_handler=None):
		generate_key = "mkdir ~/.ssh; yes | ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
		retrieve_key = "(%s) > /dev/null 2>&1; cat ~/.ssh/id_rsa.pub" % generate_key
		pubkey_results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, retrieve_key, timeout=20)
		if pubkey_results.returncode != 0:
			if output_handler:
				output_handler.append({1: "Failed to connect to the testing instance. Please try again."})
			self.logger.error("Failed to set up ssh on vm at %s, results: %s" % (self.vm_id, pubkey_results))
			return pubkey_results
		pubkey = pubkey_results.output
		alias = '__vm_%s:%s' % (self.vm_id, uuid.uuid1())
		PubkeyRegistrar().register_pubkey(VerificationUser.id, alias, pubkey)
		try:
			return authorized_command()
		finally:
			PubkeyRegistrar().unregister_pubkey(VerificationUser.id, alias)

	def cache_repository(self, repo_name, output_handler=None):
		return self.ssh_call(';'.join(('sudo chown -R %s:%s %s' % (self.vm_username, self.vm_username, repo_name),
			'mv %s /repositories/cached/%s || rm -rf %s' % (repo_name, repo_name, repo_name))), output_handler)

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
