#!/usr/bin/python
import os
import sys


def main():
	repo_path = os.getcwd()
	main_repo_path = repo_path[:repo_path.rfind('.git')] + '.git'
	private_key = main_repo_path + '.id_rsa'

	timeout = os.environ.get('GIT_SSH_TIMEOUT', 120)

	os.execlp('timeout', 'timeout', str(timeout),
		'ssh', '-q',
		'-i', private_key,
		'-oStrictHostKeyChecking=no',
		'-oUserKnownHostsFile=/dev/null',
		*sys.argv[1:])


if __name__ == '__main__':
	main()
