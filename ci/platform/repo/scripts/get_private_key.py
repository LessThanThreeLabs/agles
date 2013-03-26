#!/usr/bin/python
import os
import sys

from subprocess import Popen


def main():
	repo_path = os.getcwd()
	main_repo_path = repo_path[:repo_path.rfind('.git')] + '.git'
	private_key = main_repo_path + '.id_rsa'

	spawn_timeout_daemon(os.getpid(), float(os.environ.get('GIT_SSH_TIMEOUT', 120)))

	os.execlp('ssh', 'ssh', '-q',
		'-i', private_key,
		'-oStrictHostKeyChecking=no',
		'-oUserKnownHostsFile=/dev/null',
		*sys.argv[1:])


def spawn_timeout_daemon(pid, timeout):
	Popen(['sh', '-c', 'sleep %f && kill %d' % (timeout, pid)])


if __name__ == '__main__':
	main()
