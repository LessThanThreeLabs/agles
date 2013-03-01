#!/usr/bin/env python
# verification_box_generator.py - Creates verification vagrant boxes

"""Given a base vagrant box name, this packages in a Vagrantfile
from the template in this directory and adds the resulting box
as BASE_verification to the installed box files in vagrant
"""

import os

from sys import argv
from subprocess import call, check_output
from string import Template


TEMPLATE_FILE = os.path.realpath(__file__ + '/../../verification/server/Vagrantfile.template')
VM_DIRECTORY = '/tmp/'


def get_url(box_name):
	return 'http://files.vagrantup.com/' + box_name + '.box'


def get_vagrantfile():
	return VM_DIRECTORY + 'Vagrantfile'


def have_box_installed(box_name):
	for box in check_output(['vagrant', 'box', 'list']).split():
		if box == box_name:
			return True
	return False


def main():
	if len(argv) < 2:
		print 'Must specify a base vagrant box. Suggested: lucid32, precise64'
		return

	box_name = argv[1]

	if have_box_installed(box_name):
		print 'Already have base box:', box_name
	else:
		print 'Downloading base box file:', box_name
		call(['vagrant', 'box', 'add', box_name, get_url(box_name)])

	print 'Generating vagrantfile from template'
	with open(TEMPLATE_FILE) as template_file:
		vagrantfile_template = Template(template_file.read())
		vagrantfile_contents = vagrantfile_template.substitute(box_name=box_name)
	with open(get_vagrantfile(), 'w') as vagrantfile:
		vagrantfile.write(vagrantfile_contents)

	print 'Changing into directory:', VM_DIRECTORY
	os.chdir(VM_DIRECTORY)

	print 'Launching vagrant box', box_name
	call(['vagrant', 'up'])

	print 'Packaging vagrant box', box_name, 'with template Vagrantfile'
	call(['vagrant', 'package', '--vagrantfile', get_vagrantfile()])

	print 'Destroying vagrant box', box_name
	call(['vagrant', 'destroy', '-f'])

	verification_box_name = argv[2] if len(argv) == 3 else box_name + '_verification'
	if have_box_installed(verification_box_name):
		print "Removing existing verification box:", verification_box_name
		call(['vagrant', 'box', 'remove', verification_box_name])

	print 'Adding verification box:', verification_box_name
	call(['vagrant', 'box', 'add', verification_box_name, 'package.box'])

	print 'Cleaning up temp files'
	os.remove('package.box')
	os.remove(get_vagrantfile())

if __name__ == '__main__':
	main()
