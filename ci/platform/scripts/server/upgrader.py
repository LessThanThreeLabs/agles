#!/usr/bin/env python
import logging
import multiprocessing
import sys

import util.log

from upgrade.upgrader import Upgrader, HttpTarFetcher


def main():
	upgrade_version = sys.argv[1] if len(sys.argv) > 1 else 'latest'
	print 'Preparing to upgrade to version %s ...' % upgrade_version

	util.log.configure()

	try:
		upgrader = Upgrader(upgrade_version, HttpTarFetcher())

		upgrade_process = multiprocessing.Process(target=upgrader.run)
		upgrade_process.start()

		upgrade_process.join()
		if upgrade_process.exitcode < 0:
			raise Exception('Upgrade process killed by signal %d' % (-upgrade_process.exitcode))
		elif upgrade_process.exitcode > 0:
			raise Exception('Upgrade process exited with return code %d' % upgrade_process.exitcode)
	except:
		logger = logging.getLogger('upgrader')
		logger.critical('Upgrade failure', exc_info=True)


if __name__ == '__main__':
	main()
