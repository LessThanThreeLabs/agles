#!/usr/bin/python
import settings.log

from util.uri_translator import RepositoryUriTranslator
from verification.master import VerificationMaster


def main():
	print "Starting Verification Master ..."

	settings.log.configure()
	master = VerificationMaster(RepositoryUriTranslator())
	master.run()


if __name__ == "__main__":
	main()
