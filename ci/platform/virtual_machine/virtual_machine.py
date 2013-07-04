import uuid

from database.engine import ConnectionFactory
from shared.constants import VerificationUser
from streaming_executor import StreamingExecutor
from util.log import Logged
from verification.pubkey_registrar import PubkeyRegistrar


@Logged()
class VirtualMachine(object):
	"""A minimal virtual machine representation"""
	def __init__(self, vm_id, redis_connection=None):
		self.vm_id = vm_id
		self._redis_conn = redis_connection or ConnectionFactory.get_redis_connection('virtual_machine')

	def provision(self, private_key, output_handler=None):
		raise NotImplementedError()

	def export(self, export_prefix, files, output_handler=None):
		raise NotImplementedError("Currently only supported for EC2 VMs")

	def ssh_call(self, command, output_handler=None, timeout=None):
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

	# TODO(andrey) fix this function
	def remote_checkout(self, repo_name, repo_url, repo_type, ref, output_handler=None):
		def _remote_fetch():
			host_url = repo_url[:repo_url.find(":")]
			command = ' && '.join([
				'(mv /repositories/cached/%s source > /dev/null 2>&1 || (rm -rf source > /dev/null 2>&1; git init source))' % repo_name,
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null 2>&1' % host_url,  # Bypass the ssh yes/no prompt
				'cd source',
				'git fetch %s %s -n --depth 1' % (repo_url, ref),
				'git checkout FETCH_HEAD'])
			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out ref %s from %s, results: %s" % (ref, repo_url, results), exc_info=True)
			return results

		# TODO(andrey) decide on name of ssh function.
		def _remote_update():
			host_url, _, repo_uri = repo_url.split('://')[1].partition('/')
			command = ' && '.join([
				# TODO(andrey) very bad! fix me!
				'sudo apt-get install -y mercurial',
				'(mv /repositories/cached/%s source > /dev/null 2>&1 || (rm -rf source > /dev/null 2>&1; hg init source))' % repo_name,
				'cd source',
				'mkdir .hg/strip-backup',
				'ssh -oStrictHostKeyChecking=no -q %s \"hg cat-bundle %s %s\" | base64 -d > .hg/strip-backup/%s.hg' % (host_url, repo_uri, ref, ref),	# Bypass the ssh yes/no prompt
				'hg pull %s' % repo_url,
				'hg unbundle .hg/strip-backup/%s.hg' % ref,
				'hg update %s' % ref])
			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to check out bundle %s from %s, results: %s" % (ref, repo_url, results), exc_info=True)
			return results

		if repo_type == 'git':
			assert isinstance(ref, str)
			return self._ssh_authorized(_remote_fetch, output_handler)
		elif repo_type == 'hg':
			return self._ssh_authorized(_remote_update, output_handler)
		else:
			self.logger.error("Unknown repository type in remote_checkout %s." % repo_type)

	# TODO(andrey) make this work for hg (easy)
	def remote_clone(self, repo_url, output_handler=None):
		def _remote_clone():
			host_url = repo_url[:repo_url.find(":")]
			command = ' && '.join([
				'if [ -e source ]; then rm -rf source; fi',  # Make sure there's no "source" directory. Especially important for retries
				'ssh -oStrictHostKeyChecking=no %s true > /dev/null 2>&1' % host_url,  # Bypass the ssh yes/no prompt
				'git clone %s source' % repo_url])
			results = self._try_multiple_times(5, lambda results: results.returncode == 0, self.ssh_call, command, output_handler)
			if results.returncode != 0:
				self.logger.error("Failed to clone %s, results: %s" % (repo_url, results), exc_info=True)
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
		return self.ssh_call('mv source /repositories/cached/%s || rm -rf source' % repo_name, output_handler)

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
			major_version, minor_version = float(name_parts[-2]), float(name_parts[-1])
		except (IndexError, ValueError):
			try:
				major_version, minor_version = float(name_parts[-1]), -1
			except:
				major_version, minor_version = -1, -1
		return major_version, minor_version
