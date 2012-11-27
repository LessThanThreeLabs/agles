#!/usr/bin/python
from verification.master import VerificationMaster


def main():
	print "Starting Verification Master ..."

	master = VerificationMaster()
	master.run()


if __name__ == "__main__":
	main()
