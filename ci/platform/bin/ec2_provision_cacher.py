#!/usr/bin/env python
import time

from collections import Counter

import model_server

from settings.aws import AwsSettings
from shared.constants import VerificationUser
from util.uri_translator import RepositoryUriTranslator
from virtual_machine.ec2 import Ec2Vm


def main():
	vm_class = Ec2Vm
	newest_global_image = vm_class.get_newest_global_image()
	newest_image_version = vm_class.get_image_version(vm_class.get_newest_image())
	cache_version = newest_image_version[0], newest_image_version[1] + 1
	instance_name = 'koality_cache_%d_%d' % cache_version

	print 'Creating new instance named "%s" based on image "%s"' % (instance_name, newest_global_image.name)
	virtual_machine = vm_class.from_directory_or_construct("/tmp/koality/cache/%d_%d" % cache_version, instance_name, newest_global_image.id)
	virtual_machine.wait_until_ready()

	with model_server.rpc_connect('repos', 'read') as model_rpc:
		repositories = model_rpc.get_repositories(VerificationUser.id)

	with model_server.rpc_connect('changes', 'read') as model_rpc:
		changes = model_rpc.get_changes_from_timestamp(VerificationUser.id, map(lambda repo: repo['id'], repositories), _one_week_ago())

	repo_change_counter = Counter(map(lambda change: change['repo_id'], changes))
	primary_repository_id = repo_change_counter.most_common(1)[0][0]
	primary_repository = filter(lambda repo: repo['id'] == primary_repository_id, repositories)[0]
	print 'Primary repository is "%s"' % primary_repository['name']

	branch_counter = Counter(map(lambda change: change['merge_target'], filter(lambda change: change['repo_id'] == primary_repository_id, changes)))
	primary_branch = branch_counter.most_common(1)[0][0]
	print 'Primary branch is "%s"' % primary_branch

	virtual_machine.ssh_call('sudo mkdir -p /repositories/cache && sudo chown lt3:lt3 /repositories/cache')
	uri_translator = RepositoryUriTranslator()
	for repository in repositories:
		print 'Cloning repository "%s"' % repository['name']
		virtual_machine.remote_clone(uri_translator.translate(repository['uri']))
		virtual_machine.ssh_call('rm -rf /repositories/cache/%s; mv source /repositories/cache/%s' % (repository['name'], repository['name']))

	print 'Provisioning for repository "%s" on branch "%s"' % (primary_repository['name'], primary_branch)
	virtual_machine.ssh_call('mv /repositories/cache/%s source' % primary_repository['name'])
	virtual_machine.provision(primary_repository['privatekey'])
	virtual_machine.ssh_call('mv source /repositories/cache/%s' % primary_repository['name'])

	new_image_name = '%s%d_%d' % (AwsSettings.vm_image_name_prefix, cache_version[0], cache_version[1])
	print 'Saving instance as AMI "%s"' % new_image_name
	virtual_machine.create_image(new_image_name)

	print 'Deleting instance "%s"' % instance_name
	virtual_machine.delete()


def _one_week_ago():
	return int(time.time()) - 60 * 60 * 24 * 7


if __name__ == '__main__':
	main()
