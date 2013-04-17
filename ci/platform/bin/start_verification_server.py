#!/usr/bin/env python
import argparse
import os
import sys

import util.log

from util.uri_translator import RepositoryUriTranslator
from verification.verification_server import VerificationServer
from verification.verifier_pool import VerifierPool, VirtualMachineVerifierPool
from verification.virtual_machine_cleanup_tool import VirtualMachineCleanupTool
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.openstack import OpenstackVm


def main():
	util.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument("-d", "--dir",
		help="The root directory for the virtual machine pool")
	parser.add_argument("-t", "--type",
		help="Selects the VM type. Supported options are \"aws\" and \"openstack\"")
	parser.add_argument("-c", "--count",
		help="The maximum number of virtual machines for this verification server to manage")
	parser.add_argument("-C", "--cleanup", action="store_true",
		help="Cleans up all virtual machines from previous runs on startup")
	parser.set_defaults(dir=".", count=None)
	args = parser.parse_args()

	try:
		vm_class = {
			'aws': Ec2Vm,
			'openstack': OpenstackVm,
			'mock': None
		}[args.type]
	except:
		print "Must supply either \"aws\" or \"openstack\" as a VM type"
		parser.print_usage()
		sys.exit(1)

	if args.count is not None:
		try:
			max_vm_count = int(args.count)
		except:
			print "Must supply an integer for VM count"
			parser.print_usage()
			sys.exit(1)
	else:
		max_vm_count = None

	vm_dir = os.path.realpath(args.dir)

	if args.cleanup:
		print "Cleaning up Verification Server directory %s ..." % vm_dir
		VirtualMachineCleanupTool(vm_dir, vm_class).cleanup(filesystem=False)

	print "Starting Verification Server (%s) with directory %s ..." % (args.type, vm_dir)

	try:
		if vm_class is not None:
			verifier_pool = VirtualMachineVerifierPool(vm_class, vm_dir, max_verifiers=max_vm_count, uri_translator=RepositoryUriTranslator())
		else:
			verifier_pool = VerifierPool(max_vm_count, 0)
		verification_server = VerificationServer(verifier_pool, RepositoryUriTranslator()).run()
	except:
		print "Failed to start Verification Server"
		raise
	print "Successfully started Verification Server"
	verification_server.wait()


if __name__ == "__main__":
	main()
