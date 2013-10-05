import datetime
import time

from collections import Counter

import model_server
import yaml

from settings.store import StoreSettings
from shared.constants import BuildStatus, VerificationUser
from util.log import Logged
from util.uri_translator import RepositoryUriTranslator
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.docker import DockerVm
from virtual_machine.openstack import OpenstackVm


@Logged()
class SnapshotDaemon(object):
	def __init__(self, snapshotter, first_snapshot_time, snapshot_period):
		self.snapshotter = snapshotter
		self.first_snapshot_time = first_snapshot_time
		self.snapshot_period = snapshot_period
		self.last_snapshot_time = None

	def run(self):
		while True:
			next_snapshot_time = self.next_snapshot_time()
			self.logger.info('Taking next scheduled snapshot at %s' % next_snapshot_time)
			self.sleep_until(next_snapshot_time)
			self.last_snapshot_time = next_snapshot_time
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
		sleep_time = (wake_time - datetime.datetime.now()).total_seconds()
		sleep_time = max(sleep_time, 0)
		time.sleep(sleep_time)

	def next_snapshot_time(self):
		if self.last_snapshot_time is None:
			return self.first_snapshot_time
		else:
			return self.last_snapshot_time + datetime.timedelta(seconds=self.snapshot_period)


@Logged()
class Snapshotter(object):
	def __init__(self, vm_class):
		assert issubclass(vm_class, (Ec2Vm, OpenstackVm))
		self.vm_class = vm_class

	def snapshot(self):
		base_image = self.vm_class.get_base_image()
		current_snapshot_version = self.vm_class.get_snapshot_version(self.vm_class.get_active_image())
		new_snapshot_version = current_snapshot_version + 1 if current_snapshot_version is not None else 0
		instance_name = self.vm_class.format_snapshot_name(base_image, new_snapshot_version)

		with model_server.rpc_connect('repos', 'read') as model_rpc:
			repositories = model_rpc.get_repositories(VerificationUser.id)

		if not repositories:
			self.logger.warn('No repositories found, skipping snapshotting.')
			return

		with model_server.rpc_connect('changes', 'read') as model_rpc:
			changes = model_rpc.get_changes_between_timestamps(VerificationUser.id, map(lambda repo: repo['id'], repositories), self._30_days_ago())

		if not changes:
			self.logger.warn('No changes found in the last 30 days, skipping snapshotting.')
			return

		self.logger.info('Creating new instance named "%s" based on image "%s"' % (instance_name, self.vm_class.get_image_name(base_image)))
		virtual_machine = self.spawn_virtual_machine(new_snapshot_version, instance_name, base_image)

		try:
			virtual_machine.wait_until_ready()

			virtual_machine.configure_ssh(StoreSettings.ssh_private_key)

			uri_translator = RepositoryUriTranslator()
			self.clone_repositories(virtual_machine, repositories, uri_translator)

			repo_change_counter = Counter(map(lambda change: change['repo_id'], changes))

			# Provision in order of increasing repository push frequency
			for repository_id in map(lambda count: count[0], reversed(repo_change_counter.most_common())):
				repository = filter(lambda repo: repo['id'] == repository_id, repositories)[0]
				self.provision_for_repository(virtual_machine, repository, changes, uri_translator)

			new_image_name = instance_name

			self.logger.info('Saving instance as snapshot "%s"' % new_image_name)
			virtual_machine.create_image(new_image_name)

			self.wait_for_image(new_image_name)
		finally:
			self.logger.info('Deleting instance "%s"' % instance_name)
			virtual_machine.delete()

	def spawn_virtual_machine(self, snapshot_version, instance_name, image):
		return self.vm_class.from_id_or_construct(-int(snapshot_version) or -1, instance_name, image)

	def clone_repositories(self, virtual_machine, repositories, uri_translator):
		virtual_machine.ssh_call('sudo mkdir -p /repositories/cached && sudo chown -R %s:%s /repositories/cached' % (virtual_machine.vm_username, virtual_machine.vm_username))
		for repository in repositories:
			self.logger.info('Cloning repository "%s"' % repository['name'])
			if virtual_machine.remote_clone(repository['type'], repository['name'], uri_translator.translate(repository['uri'])).returncode != 0:
				raise Exception('Failed to clone repository "%s"' % repository['name'])
			virtual_machine.ssh_call('rm -rf /repositories/cached/%s; mv %s /repositories/cached/%s' % (repository['name'], repository['name'], repository['name']))

	def provision_for_repository(self, virtual_machine, repository, changes, uri_translator):
		repo_changes = filter(lambda change: change['repo_id'] == repository['id'], changes)
		valid_changes = filter(lambda change: ' ' not in change['merge_target'], repo_changes)
		passed_changes = filter(lambda change: change['verification_status'] == BuildStatus.PASSED, valid_changes)
		branch_counter = Counter(map(lambda change: change['merge_target'], passed_changes))
		if not branch_counter.most_common():
			return
		primary_branch = branch_counter.most_common(1)[0][0]
		self.provision_for_branch(virtual_machine, repository, primary_branch, uri_translator)

	def provision_for_branch(self, virtual_machine, repository, branch, uri_translator):
		self.logger.info('Provisioning for repository "%s" on branch "%s"' % (repository['name'], branch))
		if virtual_machine.remote_checkout(repository['name'], uri_translator.translate(repository['uri']), repository['type'], branch).returncode != 0:
			raise Exception('Failed to checkout branch "%s" for repository "%s"' % (branch, repository['name']))
		config_contents_results = virtual_machine.ssh_call('cd ~/%s && ls -A | grep koality.yml | xargs cat' % repository['name'])
		if config_contents_results.returncode != 0:
			raise Exception('Could not find a koality.yml or .koality.yml file for branch "%s" for repository "%s"' % (branch, repository['name']))
		config_contents = yaml.safe_load(config_contents_results.output)
		provision_results = virtual_machine.provision(repository['name'], {}, config_contents.get('languages'), config_contents.get('setup'))
		if provision_results.returncode != 0:
			failure_message = 'Provisioning failed with returncode %d' % provision_results.returncode
			self.logger.error(failure_message + '\nProvision output:\n%s' % provision_results.output)
			raise Exception(failure_message)
		virtual_machine.cache_repository(repository['name'])

	# TODO (bbland): move this stuff into the vm wrapper implementations
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

		images = self.vm_class.get_snapshots(self.vm_class.get_base_image())
		local_images = sorted(images, key=self.vm_class.get_snapshot_version, reverse=True)

		stale_images = local_images[3:]
		for image in stale_images:
			self.logger.info('Removing snapshot %s' % image.name)
			delete_image(image)

	def _30_days_ago(self):
		return int(time.time()) - 60 * 60 * 24 * 30


@Logged()
class DockerSnapshotter(Snapshotter):
	def spawn_virtual_machine(self, snapshot_version, instance_name, image):
		virtual_machine = super(DockerSnapshotter, self).spawn_virtual_machine(snapshot_version, instance_name, image)
		return DockerVm(virtual_machine)
