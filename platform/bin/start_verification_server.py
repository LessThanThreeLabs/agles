#!/usr/bin/python
import argparse
import os

from verification_server import VerificationServer

from settings.model_server import model_server_rpc_address

DEFAULT_MODEL_SERVER_ADDRESS = model_server_rpc_addresss
DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--model_server_address",
			help="The model server address to connect this server to")
	parser.add_argument("-v", "--vm_dir",
			help="The root directory for the virtual machine")
	parser.set_defaults(model_server_address=DEFAULT_MODEL_SERVER_ADDRESS,
			vm_dir=DEFAULT_VM_DIRECTORY)
	args = parser.parse_args()

	vm_dir = os.path.realpath(args.vm_dir)
	print "Starting Verification Server on %s with vm directory %s ..." % (
		args.model_server_address, vm_dir)

	vs = VerificationServer(args.model_server_address, vm_dir)
	vs.run()


main()
