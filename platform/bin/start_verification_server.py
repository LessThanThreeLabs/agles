#!/usr/bin/python
import argparse
import os

from settings.verification_server import box_name
from verification.server import VerificationServer
from verification.server.build_verifier import BuildVerifier
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

	verifier = BuildVerifier(Vagrant(vm_dir, box_name))
	verifier.setup()
	vs = VerificationServer(verifier)
	vs.run()


main()
