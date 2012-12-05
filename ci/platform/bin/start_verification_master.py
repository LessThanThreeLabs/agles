#!/usr/bin/python
from util.uri_translator import RepositoryUriTranslator
from verification.master import VerificationMaster


def main():
	print "Starting Verification Master ..."

	master = VerificationMaster(RepositoryUriTranslator())
	master.run()


if __name__ == "__main__":
	main()
