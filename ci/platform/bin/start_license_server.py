#!/usr/bin/env python
from license import license_verifier


def main():
	print "Starting license server..."
	key_verifier = license_verifier.HttpLicenseKeyVerifier()
	ls = license_verifier.LicenseVerifier(key_verifier).run()
	print "License server started"
	ls.wait()


if __name__ == "__main__":
	main()
