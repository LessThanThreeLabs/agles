#!/usr/bin/env python
from util import greenlets

import argparse
import sys

import model_server
import util.log

from settings.verification_server import VerificationServerSettings
from util.uri_translator import RepositoryUriTranslator
from verification.change_verifier import ChangeVerifier
from verification.verification_server import VerificationServer
from verification.verifier_pool import VerifierPool, VirtualMachineVerifierPool, DockerVirtualMachineVerifierPool
from verification.virtual_machine_cleanup_tool import VirtualMachineCleanupTool
from virtual_machine.docker import DockerVm
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.hpcloud import HpCloudVm
from virtual_machine.rackspace import RackspaceVm


def main():
	util.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument('-p', '--provider',
		help='Selects the cloud provider. Supported options are "aws" and "docker"')  # or "mock" for testing
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
			'docker': DockerVm,
			'hpcloud': HpCloudVm,
			'rackspace': RackspaceVm,
			'mock': None
		}[cloud_provider]
	except:
		print 'Must supply either "aws" or "docker" as a cloud provider'
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
		verifier_pools = {}

		if vm_class == DockerVm:
			verifier_pools[0] = DockerVirtualMachineVerifierPool(max_running=32, min_ready=0, uri_translator=RepositoryUriTranslator(), pool_id=0)
		elif vm_class is not None:
			with model_server.rpc_connect('system_settings', 'read') as rpc_client:
				pool_parameters = rpc_client.get_verifier_pool_parameters(1)
			for pool in pool_parameters:
				verifier_pools[pool['id']] = VirtualMachineVerifierPool(vm_class, max_running=pool['max_running'], min_ready=pool['min_ready'], uri_translator=RepositoryUriTranslator(), pool_id=pool['id'])
		else:
			verifier_pools[0] = VerifierPool(max_vm_count, 0)

		change_verifier = ChangeVerifier(verifier_pools, RepositoryUriTranslator())
		verification_server = VerificationServer(change_verifier).run()
	except:
		print 'Failed to start Verification Server'
		raise
	print 'Successfully started Verification Server'
	verification_server.wait()


if __name__ == '__main__':
	main()
