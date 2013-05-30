#!/usr/bin/env python
import os
import sys


def main():
	upgrade_version = sys.argv[1] if len(sys.argv) > 1 else 'latest'
	print 'Preparing to upgrade to version %s ...' % upgrade_version

	try:
		pid = os.fork()
		if pid != 0:
			os.waitpid(pid, 0)
		else:
			stdin = open('/dev/null', 'r')
			stdout = open('/dev/null', 'a+')
			stderr = open('/dev/null', 'a+', 0)
			os.dup2(stdin.fileno(), sys.stdin.fileno())
			os.dup2(stdout.fileno(), sys.stdout.fileno())
			os.dup2(stderr.fileno(), sys.stderr.fileno())

			from upgrade.upgrader import Upgrader, HttpTarFetcher

			upgrader = Upgrader(upgrade_version, HttpTarFetcher())
			upgrader.do_upgrade()
	except:
		import traceback
		with open('/tmp/err', 'w') as f:
			traceback.print_exc(file=f)


if __name__ == '__main__':
	main()
