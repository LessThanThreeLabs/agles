#!/usr/bin/python
import argparse
import os

from settings.verification_server import box_name
from verification.server import VerificationServer
from util.vagrant import Vagrant

DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--vm_dir",
			help="The root directory for the virtual machine")
	parser.set_defaults(vm_dir=DEFAULT_VM_DIRECTORY)
	args = parser.parse_args()

	vm_dir = os.path.realpath(args.vm_dir)
	print "Starting Verification Server with vm directory %s ..." % (
			vm_dir)

	vs = VerificationServer(Vagrant(vm_dir, box_name))
	vs.run()


main()
