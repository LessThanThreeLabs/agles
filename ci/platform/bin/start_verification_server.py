#!/usr/bin/env python
import argparse
import os

import settings.log

from settings.verification_server import VerificationServerSettings
from util.uri_translator import RepositoryUriTranslator
from verification.server import VerificationServer
from verification.server.build_verifier import BuildVerifier
from virtual_machine.openstack import OpenstackVm
from virtual_machine.vagrant import Vagrant

DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	settings.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--vm_dir",
		help="The root directory for the virtual machine")
	parser.add_argument("-f", "--fast_startup", action='store_true',
		help="Skips cycling of virtual machine, assumes it is already running")
	parser.add_argument("-c", "--cloud", action='store_true',
		help="Uses cloud-based virtual machine instead of a local vm")
	parser.set_defaults(vm_dir=DEFAULT_VM_DIRECTORY, fast_startup=False)
	args = parser.parse_args()

	vm_dir = os.path.realpath(args.vm_dir)
	print "Starting Verification Server (%s) with vm directory %s ..." % (
			"cloud" if args.cloud else "local", vm_dir)

	virtual_machine = OpenstackVm.from_directory_or_construct(vm_dir) if args.cloud else Vagrant(vm_dir, VerificationServerSettings.local_box_name)

	verifier = BuildVerifier.for_virtual_machine(virtual_machine, RepositoryUriTranslator())
	if not args.fast_startup:
		verifier.setup()

	print "Verifier ready"

	vs = VerificationServer(verifier)
	vs.run()


if __name__ == "__main__":
	main()
