#!/usr/bin/env python
import os
import sys


def main():
	private_key = os.environ.get('GIT_PRIVATE_KEY_PATH')
	if private_key is None:
		raise Exception('Private key not found. Please check your system configuration.')

	timeout = os.environ.get('GIT_SSH_TIMEOUT', 120)

	os.execlp('timeout', 'timeout', str(timeout),
		'ssh', '-q',
		'-i', private_key,
		'-oStrictHostKeyChecking=no',
		'-oUserKnownHostsFile=/dev/null',
		*sys.argv[1:])


if __name__ == '__main__':
	main()
