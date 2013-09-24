#!/usr/bin/env python
import argparse
import sys

import util.log

from settings.verification_server import VerificationServerSettings
from util.uri_translator import RepositoryUriTranslator
from verification.change_verifier import ChangeVerifier
from verification.verification_server import VerificationServer
from verification.verifier_pool import VerifierPool, VirtualMachineVerifierPool
from verification.virtual_machine_cleanup_tool import VirtualMachineCleanupTool
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.hpcloud import HpCloudVm
from virtual_machine.rackspace import RackspaceVm


def main():
	util.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument('-p', '--provider',
		help='Selects the cloud provider. Supported options are "aws". "hpcloud", and "rackspace"')  # or "mock" for testing
	parser.add_argument('-c', '--count',
		help='The maximum number of virtual machines for this verification server to manage')
	parser.add_argument('-C', '--cleanup', action='store_true',
		help='Cleans up all virtual machines from previous runs on startup')
	parser.set_defaults(count=None)
	args = parser.parse_args()

	try:
		cloud_provider = args.provider
		if cloud_provider is None:
			cloud_provider = VerificationServerSettings.cloud_provider
			if cloud_provider is None:
				print 'Cloud provider not specified and not in stored settings; exiting'
				sys.exit(1)
			else:
				print 'Cloud provider not specified; defaulting to the stored settings value (%s)' % cloud_provider

		vm_class = {
			'aws': Ec2Vm,
			'hpcloud': HpCloudVm,
			'rackspace': RackspaceVm,
			'mock': None
		}[cloud_provider]
	except:
		print 'Must supply either "aws", "hpcloud", or "rackspace" as a cloud provider'
		parser.print_usage()
		sys.exit(1)

	if args.count is not None:
		try:
			max_vm_count = int(args.count)
		except:
			print 'Must supply an integer for VM count'
			parser.print_usage()
			sys.exit(1)
	else:
		max_vm_count = None

	if args.cleanup:
		print 'Cleaning up Verification Server pool...'
		VirtualMachineCleanupTool(vm_class).cleanup()

	print 'Starting Verification Server (%s)...' % cloud_provider

	try:
		if vm_class is not None:
			verifier_pool = VirtualMachineVerifierPool(vm_class, max_running=max_vm_count, uri_translator=RepositoryUriTranslator())
		else:
			verifier_pool = VerifierPool(max_vm_count, 0)
		change_verifier = ChangeVerifier(verifier_pool, RepositoryUriTranslator())
		verification_server = VerificationServer(change_verifier).run()
	except:
		print 'Failed to start Verification Server'
		raise
	print 'Successfully started Verification Server'
	verification_server.wait()


if __name__ == '__main__':
	main()
