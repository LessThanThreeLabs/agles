#!/usr/bin/env python
import argparse
import os
import sys
import time

import settings.log

from util.uri_translator import RepositoryUriTranslator
from verification.server import VerificationServer
from verification.server.build_verifier import BuildVerifier
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.openstack import OpenstackVm

DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	settings.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--vm_dir",
		help="The root directory for the virtual machine")
	parser.add_argument("-f", "--fast_startup", action='store_true',
		help="Skips cycling of virtual machine, assumes it is already running")
	parser.add_argument("-a", "--aws", action='store_true',
		help="Uses an AWS virtual machine")
	parser.add_argument("-o", "--openstack", action='store_true',
		help="Uses an Openstack virtual machine")
	parser.set_defaults(vm_dir=DEFAULT_VM_DIRECTORY, fast_startup=False)
	args = parser.parse_args()

	if not args.aws and not args.openstack:
		print "Must supply either --aws or --openstack to specify the VM type"
		sys.exit(1)

	vm_dir = os.path.realpath(args.vm_dir)
	print "Starting Verification Server (%s) with vm directory %s ..." % (
			"openstack" if args.openstack else "aws", vm_dir)

	vm_class = OpenstackVm if args.openstack else Ec2Vm

	verifiers = []
	for i in range(4):
		for attempts in range(9, -1, -1):
			try:
				virtual_machine = vm_class.from_directory_or_construct(os.path.join(vm_dir, str(i)))
			except Exception as e:
				print e
				if attempts > 0:
					print "Failed to create virtual machine, trying again in 3 seconds..."
					time.sleep(3)
				else:
					print "Failed 10 times, aborting."
					sys.exit(1)
			else:
				break

		verifier = BuildVerifier.for_virtual_machine(virtual_machine, RepositoryUriTranslator())
		verifiers.append(verifier)

		print "Verifier %d ready" % i

	if not args.fast_startup:
		for verifier in verifiers:
			verifier.setup()

	print "Run time..."

	vs = VerificationServer(*verifiers)
	vs.run()


if __name__ == "__main__":
	main()
