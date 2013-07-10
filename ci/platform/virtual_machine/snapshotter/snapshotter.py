import datetime
import time

from collections import Counter

import model_server

from settings.store import StoreSettings
from shared.constants import VerificationUser
from util.log import Logged
from util.uri_translator import RepositoryUriTranslator
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.openstack import OpenstackVm


@Logged()
class SnapshotDaemon(object):
	def __init__(self, snapshotter, next_snapshot, snapshot_frequency):
		self.snapshotter = snapshotter
		self.next_snapshot = next_snapshot
		self.snapshot_frequency = snapshot_frequency
		self.last_snapshot_time = None

	def run(self):
		while True:
			next_snapshot_time = self.next_snapshot_time()
			self.logger.debug('Taking next scheduled snapshot at %s' % next_snapshot_time)
			self.sleep_until(next_snapshot_time)
			try:
				self.logger.info('Taking scheduled snapshot')
				self.snapshotter.snapshot()
			except:
				self.logger.error('Failed to take scheduled snapshot', exc_info=True)
			try:
				self.snapshotter.remove_stale_snapshots()
			except:
				self.logger.error('Failed to remove stale snapshots', exc_info=True)

	def sleep_until(self, wake_time):
		time.sleep((wake_time - datetime.datetime.now()).total_seconds())

	def next_snapshot_time(self):
		now = datetime.datetime.now()
		then = datetime.datetime(now.year, now.month, now.day, 3)
		if now.hour >= 3:
			then += datetime.timedelta(days=1)
		return then


@Logged()
class Snapshotter(object):
	def __init__(self, vm_class):
		self.vm_class = vm_class

	def snapshot(self):
		newest_global_image = self.vm_class.get_newest_global_image()
		newest_image_version = self.vm_class.get_image_version(self.vm_class.get_newest_image())
		snapshot_version = newest_image_version[0], newest_image_version[1] + 1
		snapshot_version = self._truncate_decimal(snapshot_version[0]), self._truncate_decimal(snapshot_version[1])
		instance_name = 'koality_snapshot_%s_%s' % snapshot_version

		with model_server.rpc_connect('repos', 'read') as model_rpc:
			repositories = model_rpc.get_repositories(VerificationUser.id)

		if not repositories:
			self.logger.warn('No repositories found, skipping snapshotting.')
			return

		with model_server.rpc_connect('changes', 'read') as model_rpc:
			changes = model_rpc.get_changes_between_timestamps(VerificationUser.id, map(lambda repo: repo['id'], repositories), self._one_week_ago())

		if not changes:
			self.logger.warn('No changes found in the last week, skipping snapshotting.')
			return

		self.logger.info('Creating new instance named "%s" based on image "%s"' % (instance_name, newest_global_image.name))
		virtual_machine = self.vm_class.from_id_or_construct('cached:%s_%s' % snapshot_version, instance_name, newest_global_image.id)

		try:
			virtual_machine.wait_until_ready()

			repo_change_counter = Counter(map(lambda change: change['repo_id'], changes))
			primary_repository_id = repo_change_counter.most_common(1)[0][0]
			primary_repository = filter(lambda repo: repo['id'] == primary_repository_id, repositories)[0]
			self.logger.debug('Primary repository is "%s"' % primary_repository['name'])

			branch_counter = Counter(map(lambda change: change['merge_target'], filter(lambda change: change['repo_id'] == primary_repository_id, changes)))
			primary_branch = branch_counter.most_common(1)[0][0]
			self.logger.debug('Primary branch is "%s"' % primary_branch)

			uri_translator = RepositoryUriTranslator()
			self.clone_repositories(virtual_machine, repositories, uri_translator)
			self.provision_for_branch(virtual_machine, primary_repository, primary_branch, uri_translator)

			new_image_name = self.get_image_name(snapshot_version)

			self.logger.info('Saving instance as snapshot "%s"' % new_image_name)
			virtual_machine.create_image(new_image_name)

			self.wait_for_image(new_image_name)
		finally:
			self.logger.info('Deleting instance "%s"' % instance_name)
			virtual_machine.delete()

	def clone_repositories(self, virtual_machine, repositories, uri_translator):
		virtual_machine.ssh_call('sudo mkdir -p /repositories/cached && sudo chown -R lt3:lt3 /repositories/cached')
		for repository in repositories:
			self.logger.debug('Cloning repository "%s"' % repository['name'])
			if virtual_machine.remote_clone(uri_translator.translate(repository['uri'])).returncode != 0:
				raise Exception('Failed to clone repository "%s"' % repository['name'])
			virtual_machine.ssh_call('rm -rf /repositories/cached/%s; mv source /repositories/cached/%s' % (repository['name'], repository['name']))

	def provision_for_branch(self, virtual_machine, repository, branch, uri_translator):
		self.logger.debug('Provisioning for repository "%s" on branch "%s"' % (repository['name'], branch))
		if virtual_machine.remote_checkout(repository['name'], uri_translator.translate(repository['uri']), branch).returncode != 0:
			raise Exception('Failed to checkout branch "%s" for repository "%s%' % (branch, repository['name']))
		provision_results = virtual_machine.provision(StoreSettings.ssh_private_key)
		if provision_results.returncode != 0:
			failure_message = 'Provisioning failed with returncode %d' % provision_results.returncode
			self.logger.error(failure_message + '\nProvision output:\n%s' % provision_results.output)
			raise Exception(failure_message)
		virtual_machine.cache_repository(repository['name'])

	def get_image_name(self, snapshot_version):
		image_name_prefix = self.vm_class.Settings.vm_image_name_prefix
		if image_name_prefix.endswith(str(snapshot_version[0])):
			image_name = '%s_%s' % (image_name_prefix, snapshot_version[1])
		elif image_name_prefix.endswith('%s_' % snapshot_version[0]):
			image_name = '%s%s' % (image_name_prefix, snapshot_version[1])
		else:
			image_name = '%s%s_%s' % (image_name_prefix, snapshot_version[0], snapshot_version[1])
		return image_name

	def wait_for_image(self, image_name):
		def wait_for_ec2_image():
			while True:
				try:
					image = self.vm_class.CloudClient().get_all_images(filters={'name': image_name})[0]
				except:
					pass
				else:
					break
			while True:
				if image.state == 'available':
					break
				else:
					time.sleep(2)
					image.update()

		def wait_for_openstack_image():
			def get_image():
				while True:
					images = filter(lambda image: image.name == image_name, self.vm_class.CloudClient().list_images())
					if images:
						return images[0]
					else:
						time.sleep(2)

			image = get_image()

			while True:
				if image.extra['status'] == 'ACTIVE':
					break
				else:
					time.sleep(2)
					image = get_image()

		if issubclass(self.vm_class, Ec2Vm):
			wait_for_ec2_image()
		elif issubclass(self.vm_class, OpenstackVm):
			wait_for_openstack_image()
		else:
			self.logger.error('Unsupported VM class provided for snapshotter')

	def _truncate_decimal(self, value):
		if value == int(value):
			return int(value)
		return value

	def remove_stale_snapshots(self):
		def delete_image(image):
			def delete_ec2_image():
				image.deregister(delete_snapshot=True)

			def delete_openstack_image():
				self.vm_class.CloudClient().ex_delete_image(image)

			if issubclass(self.vm_class, Ec2Vm):
				delete_ec2_image()
			elif issubclass(self.vm_class, OpenstackVm):
				delete_openstack_image()
			else:
				self.logger.error('Unsupported VM class provided for snapshotter')

		images = self.vm_class.get_all_images()
		local_images = sorted(filter(lambda image: self.vm_class.get_image_version(image)[1] >= 0, images), key=self.vm_class.get_image_version, reverse=True)

		stale_images = local_images[2:]
		for image in stale_images:
			self.logger.info('Removing snapshot %s' % image.name)
			delete_image(image)

	def _one_week_ago(self):
		return int(time.time()) - 60 * 60 * 24 * 7 * 4
