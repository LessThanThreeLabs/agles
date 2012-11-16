#!/usr/bin/python
import argparse
import os

from settings.verification_server import box_name
from util.uri_translator import RepositoryUriTranslator
from verification.server.build_verifier import BuildVerifier
from vagrant.vagrant_wrapper import VagrantWrapper

DEFAULT_VM_DIRECTORY = "/tmp/verification"


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--vm_dir",
			help="The root directory for the virtual machine")
	parser.add_argument("-u", "--repo_uri",
			help="The uri pointing to the repository")
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

	def callback(results):
		print "Verification results: %s" % str(results)

	class ConsoleAppender(object):
		def __init__(self, type, subtype):
			self.type = type
			self.subtype = subtype

		def append(self, line, contents):
			if self.subtype:
				print "(%s,%s,%s): %s" % (self.type, self.subtype, line, contents)
			else:
				print "(%s,%s): %s" % (self.type, self.line, contents)

		def flush(self):
			print "Flushed"

	verifier.verify(args.repo_uri, [""], callback, ConsoleAppender)


main()
