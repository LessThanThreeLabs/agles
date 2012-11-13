#!/usr/bin/python
import argparse
import os

from multiprocessing import Process

from settings.verification_server import box_name
from util.uri_translator import RepositoryUriTranslator
from verification.server import VerificationServer
from verification.server.build_verifier import BuildVerifier
from vagrant.vagrant_wrapper import VagrantWrapper

DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--vm_dir",
			help="The root directory for the virtual machine")
	parser.add_argument("-f", "--fast_startup", action='store_true',
			help="Skips teardown step at beginning")
	parser.set_defaults(vm_dir=DEFAULT_VM_DIRECTORY, fast_startup=False)
	args = parser.parse_args()

	vm_dir = os.path.realpath(args.vm_dir)
	print "Starting Verification Server with vm directory %s ..." % (
			vm_dir)

	verifier = BuildVerifier(VagrantWrapper.vm(vm_dir, box_name), RepositoryUriTranslator())
	if not args.fast_startup:
		verifier.setup()

	vs = VerificationServer(verifier)
	vs_process = Process(target=vs.run)
	vs_process.daemon = True
	vs_process.start()


main()
