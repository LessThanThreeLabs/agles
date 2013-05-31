#!/usr/bin/env python
import argparse
import datetime
import sys
import time

from collections import Counter

import model_server
import util.log

from settings.aws import AwsSettings
from settings.store import StoreSettings
from shared.constants import VerificationUser
from util.uri_translator import RepositoryUriTranslator
from virtual_machine.ec2 import Ec2Client, Ec2Vm


def main():
	util.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument("-d", "--daemon", action="store_true",
		help="Runs a daemon which snapshots daily")
	parser.add_argument("-c", "--cleanup", action="store_true",
		help="Clean up old snapshots")
	args = parser.parse_args()

	if args.daemon and args.cleanup:
		raise Exception("Must select only one of (--daemon, --cleanup)")
	elif args.daemon:
		run_snapshot_daemon()
	elif args.cleanup:
		remove_stale_snapshots()
	else:
		snapshot()


def run_snapshot_daemon():
	while True:
		t = _next_3am()
		print "Taking next snapshot at %s" % t
		_sleep_until(t)
		try:
			snapshot()
			remove_stale_snapshots()
		except BaseException as e:
			print >> sys.stderr, e


def snapshot():
	vm_class = Ec2Vm
	newest_global_image = vm_class.get_newest_global_image()
	newest_image_version = vm_class.get_image_version(vm_class.get_newest_image())
	snapshot_version = newest_image_version[0], newest_image_version[1] + 1
	snapshot_version = truncate_decimal(snapshot_version[0]), truncate_decimal(snapshot_version[1])
	instance_name = 'koality_snapshot_%s_%s' % snapshot_version

	print 'Creating new instance named "%s" based on image "%s"' % (instance_name, newest_global_image.name)
	virtual_machine = vm_class.from_id_or_construct('cached:%s_%s' % snapshot_version, instance_name, newest_global_image.id)

	try:
		virtual_machine.wait_until_ready()

		with model_server.rpc_connect('repos', 'read') as model_rpc:
			repositories = model_rpc.get_repositories(VerificationUser.id)

		with model_server.rpc_connect('changes', 'read') as model_rpc:
			changes = model_rpc.get_changes_between_timestamps(VerificationUser.id, map(lambda repo: repo['id'], repositories), _one_week_ago())

		repo_change_counter = Counter(map(lambda change: change['repo_id'], changes))
		primary_repository_id = repo_change_counter.most_common(1)[0][0]
		primary_repository = filter(lambda repo: repo['id'] == primary_repository_id, repositories)[0]
		print 'Primary repository is "%s"' % primary_repository['name']

		branch_counter = Counter(map(lambda change: change['merge_target'], filter(lambda change: change['repo_id'] == primary_repository_id, changes)))
		primary_branch = branch_counter.most_common(1)[0][0]
		print 'Primary branch is "%s"' % primary_branch

		virtual_machine.ssh_call('sudo mkdir -p /repositories/cached && sudo chown -R lt3:lt3 /repositories/cached')
		uri_translator = RepositoryUriTranslator()
		for repository in repositories:
			print 'Cloning repository "%s"' % repository['name']
			virtual_machine.remote_clone(uri_translator.translate(repository['uri']))
			virtual_machine.ssh_call('rm -rf /repositories/cached/%s; mv source /repositories/cached/%s' % (repository['name'], repository['name']))

		print 'Provisioning for repository "%s" on branch "%s"' % (primary_repository['name'], primary_branch)
		virtual_machine.ssh_call('mv /repositories/cached/%s source' % primary_repository['name'])
		provision_results = virtual_machine.provision(StoreSettings.ssh_private_key)
		if provision_results.returncode != 0:
			failure_message = 'Provisioning failed with returncode %d' % provision_results.returncode
			print failure_message
			print 'Provision output:\n%s' % provision_results.output
			raise Exception(failure_message)
		virtual_machine.cache_repository(primary_repository['name'])

		new_image_name = '%s%s_%s' % (AwsSettings.vm_image_name_prefix, snapshot_version[0], snapshot_version[1])
		print 'Saving instance as AMI "%s"' % new_image_name
		virtual_machine.create_image(new_image_name)

		while True:
			try:
				image = Ec2Client.get_client().get_all_images(filters={'name': new_image_name})[0]
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

	finally:
		print 'Deleting instance "%s"' % instance_name
		virtual_machine.delete()


def truncate_decimal(value):
	if value == int(value):
		return int(value)
	return value


def remove_stale_snapshots():
	vm_class = Ec2Vm

	images = vm_class.get_all_images()
	local_images = sorted(filter(lambda image: vm_class.get_image_version(image)[1] >= 0, images), key=vm_class.get_image_version, reverse=True)

	stale_images = local_images[3:]
	for image in stale_images:
		print 'Removing snapshot %s' % image.name
		image.deregister(delete_snapshot=True)


def _sleep_until(t):
	time.sleep((t - datetime.datetime.now()).total_seconds())


def _next_3am():
	now = datetime.datetime.now()
	then = datetime.datetime(now.year, now.month, now.day, 3)
	if now.hour >= 3:
		then += datetime.timedelta(days=1)
	return then


def _one_week_ago():
	return int(time.time()) - 60 * 60 * 24 * 7


if __name__ == '__main__':
	main()
