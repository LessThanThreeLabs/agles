#!/usr/bin/env python
import argparse
import os
import sys

import settings.log

from settings.verification_server import VerificationServerSettings
from util.uri_translator import RepositoryUriTranslator
from verification.verification_server import VerificationServer
from verification.verifier_pool import VirtualMachineVerifierPool
from verification.virtual_machine_cleanup_tool import VirtualMachineCleanupTool
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.openstack import OpenstackVm


def main():
	settings.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument("-d", "--dir",
		help="The root directory for the virtual machine pool")
	parser.add_argument("-t", "--type",
		help="Selects the VM type. Supported options are \"aws\" and \"openstack\"")
	parser.add_argument("-c", "--count",
		help="The number of virtual machines for this verification server to manage")
	parser.add_argument("-C", "--cleanup", action="store_true",
		help="Cleans up all virtual machines from previous runs on startup")
	parser.set_defaults(dir=".", count=VerificationServerSettings.virtual_machine_count)
	args = parser.parse_args()

	try:
		vm_class = {
			'aws': Ec2Vm,
			'openstack': OpenstackVm
		}[args.type]
	except:
		print "Must supply either \"aws\" or \"openstack\" as a VM type"
		parser.print_usage()
		sys.exit(1)

	try:
		vm_count = int(args.count)
	except:
		print "Must supply an integer for VM count"
		parser.print_usage()
		sys.exit(1)

	vm_dir = os.path.realpath(args.dir)

	if args.cleanup:
		print "Cleaning up Verification Server directory %s ..." % vm_dir
		VirtualMachineCleanupTool(vm_dir, vm_class).cleanup()

	print "Starting Verification Server (%d*%s) with directory %s ..." % (
			vm_count, args.type, vm_dir)

	verifier_pool = VirtualMachineVerifierPool(vm_class, vm_dir, vm_count, uri_translator=RepositoryUriTranslator())
	vs = VerificationServer(verifier_pool, RepositoryUriTranslator())
	vs.run()


if __name__ == "__main__":
	main()
