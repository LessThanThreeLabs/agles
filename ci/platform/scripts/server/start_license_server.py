#!/usr/bin/env python
from license import license_server


def main():
	print "Starting license server..."
	key_verifier = license_server.HttpLicenseKeyVerifier()
	ls = license_server.LicenseServer(key_verifier).run()
	print "License server started"
	ls.wait()


if __name__ == "__main__":
	main()
