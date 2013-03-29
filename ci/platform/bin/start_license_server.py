#!/usr/bin/env python
from license import license_server


def main():
	print "Starting license server..."
	ls = license_server.LicenseServer()
	print "License server started"
	ls.run()


if __name__ == "__main__":
	main()
