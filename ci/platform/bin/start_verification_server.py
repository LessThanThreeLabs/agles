#!/usr/bin/env python
import argparse
import os
import sys
import time

import settings.log

from util.uri_translator import RepositoryUriTranslator
from verification.server import VerificationServer
from verification.server.verifier_pool import VerifierPool
from verification.shared.build_core import CloudBuildCore
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.openstack import OpenstackVm


DEFAULT_VM_COUNT = 4


def main():
	settings.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument("-d", "--dir",
		help="The root directory for the virtual machine pool")
	parser.add_argument("-t", "--type",
		help="Selects the VM type. Supported options are \"aws\" and \"openstack\"")
	parser.add_argument("-c", "--count",
		help="The number of virtual machines for this verification server to manage")
	parser.set_defaults(dir=".", count=DEFAULT_VM_COUNT)
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
	print "Starting Verification Server (%d*%s) with directory %s ..." % (
			vm_count, args.type, vm_dir)

	def spawn_vm(verifier_number):
		for attempts in range(9, -1, -1):
			try:
				return vm_class.from_directory_or_construct(os.path.join(vm_dir, str(verifier_number)))
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

	def spawn_verifier(verifier_number, uri_translator):
		return CloudBuildCore(spawn_vm(verifier_number), uri_translator)

	verifier_pool = VerifierPool(spawn_verifier, vm_count, RepositoryUriTranslator())
	vs = VerificationServer(verifier_pool)
	vs.run()


if __name__ == "__main__":
	main()
