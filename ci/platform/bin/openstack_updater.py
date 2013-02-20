#!/usr/bin/python

import getpass
import os
import pipes
import shlex
import subprocess

from sys import argv

from virtual_machine.openstack import OpenstackClient, OpenstackVm


def main():
	branch = 'master'
	remote_username = 'lt3'
	remote_ip = '166.78.49.102'
	remote_host = '%s@%s' % (remote_username, remote_ip)

	current_image_name = OpenstackVm.get_newest_image().name
	prefix = current_image_name[:current_image_name.rfind('_') + 1]
	suffix = current_image_name[current_image_name.rfind('_') + 1:]
	new_image_name = "%s%d" % (prefix, int(suffix) + 1)
	print "Current newest image is %s" % current_image_name
	print "Planning to save new image %s" % new_image_name

	print "Requesting github credentials:"
	username = raw_input("Username: ")
	password = getpass.getpass()

	print "Planning to use branch '%s'..." % branch
	print "About to ssh into remote box. Password may be requested..."

	with open(os.path.join(os.environ['HOME'], '.ssh', 'id_rsa.pub')) as pubkey_file:
		local_pubkey = pubkey_file.read()
	remote_command = 'grep %s .ssh/authorized_keys > /dev/null || echo %s >> .ssh/authorized_keys' % (pipes.quote(local_pubkey), pipes.quote(local_pubkey))
	_ssh(remote_host, remote_command)

	remote_command = _and(
		"git clone https://%s:%s@github.com/Randominator/agles.git" % (username, password),
		"cd agles/ci/platform",
		"git checkout %s" % branch,
		"python setup.py install",
		"cd",
		"rm -rf agles",
		"([ ! -f .bash_history ] || rm .bash_history)")  # delete .bash_history if it exists
	_ssh(remote_host, remote_command)

	if _yes_no("Provision with local koality config file?"):
		default_path = _get_config_file_path()
		file_path = _prompt("Path to koality config file", default_path)
		if not os.access(file_path, os.F_OK):
			print "File %s does not exist, aborting." % file_path
			return
		with open(file_path) as config_file:
			config = config_file.read()
		_ssh(remote_host, _and(
			"cp .bash_profile .bash_profile.bak",
			"echo %s > /tmp/koality.yml" % pipes.quote(config),
			"python -u -c " +
				"\"from provisioner.provisioner import Provisioner; Provisioner().provision('', config_path='/tmp/koality.yml')\"",
			"([ ! -f /tmp/koality.yml ] || rm /tmp/koality.yml)",
			"mv .bash_profile.bak .bash_profile"))

	if _yes_no("Continue saving image %s?" % new_image_name):
		server = OpenstackClient.get_client().servers.find(accessIPv4=remote_ip)
		OpenstackClient.get_client().servers.create_image(server, new_image_name)
		print "Image is currently being saved. Allow up to 20 minutes to take effect."
	else:
		print "Aborting"


def _ssh(remote_host, command):
	return subprocess.check_call(shlex.split('ssh %s %s' % (remote_host, pipes.quote(command))))


def _and(*commands):
	return ' && '.join(commands)


def _yes_no(message):
	response = _prompt("%s (y/N)" % message)
	if response:
		return response.lower() in ['y', 'yes']


def _prompt(message, default=None):
	return raw_input("%s%s:\n" % (message, " (%s)" % default if default else "")) or default


def _get_config_file_path():
	git_root = subprocess.check_output(shlex.split('git rev-parse --show-toplevel')).strip()
	for config_filename in ['koality.yml', '.koality.yml']:
		config_path = os.path.join(git_root, config_filename)
		if os.access(config_path, os.F_OK):
			return config_path

if __name__ == '__main__':
	main()
