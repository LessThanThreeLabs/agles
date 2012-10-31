#!/usr/bin/python
import argparse
import os

from settings.verification_server import box_name
from verification.server.build_verifier import BuildVerifier
from vagrant.vagrant_wrapper import VagrantWrapper

DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--vm_dir",
			help="The root directory for the virtual machine")
	parser.add_argument("-u", "--repo_uri",
			help="The uri pointing to the repository")
	parser.add_argument("-f", "--fast_startup", action='store_true',
			help="Skips teardown step at beginning")
	parser.set_defaults(vm_dir=DEFAULT_VM_DIRECTORY, fast_startup=False)
	args = parser.parse_args()

	vm_dir = os.path.realpath(args.vm_dir)
	print "Starting Verification Server with vm directory %s ..." % (
			vm_dir)

	verifier = BuildVerifier(VagrantWrapper.vm(vm_dir, box_name))
	if not args.fast_startup:
		verifier.setup()

	def callback(results):
		print "Verification results: %s" % str(results)

	def console_appender(console):
		def output_handler(line, contents):
			print "(%s,%s): %s" % (console, line, contents)
		return output_handler

	verifier.verify(args.repo_uri, [""], callback, console_appender)


main()
