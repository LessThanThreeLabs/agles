#!/usr/bin/env python
import argparse
import os
import sys
import time

import settings.log

from settings.verification_server import VerificationServerSettings
from util.uri_translator import RepositoryUriTranslator
from verification.server import VerificationServer
from verification.server.verifier_pool import VerifierPool
from verification.server.virtual_machine_cleanup_tool import VirtualMachineCleanupTool
from verification.shared.build_core import CloudBuildCore
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

	def spawn_vm(verifier_number):
		while True:
			try:
				return vm_class.from_directory_or_construct(os.path.join(vm_dir, str(verifier_number)))
			except:
				print "Failed to create virtual machine, trying again in 3 seconds..."
				time.sleep(3)
			else:
				break

	def spawn_verifier(verifier_number, uri_translator):
		return CloudBuildCore(spawn_vm(verifier_number), uri_translator)

	verifier_pool = VerifierPool(spawn_verifier, vm_count, RepositoryUriTranslator())
	vs = VerificationServer(verifier_pool)
	vs.run()


if __name__ == "__main__":
	main()
