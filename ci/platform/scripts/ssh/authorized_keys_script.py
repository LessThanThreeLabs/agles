#!/usr/bin/env python
import os
import re
import sys

import model_server

GITSERVE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "koality-gitserve")
FORCED_COMMAND = 'command="%s %d",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty'
valid_key = re.compile('^ssh-(?:dss|rsa) [A-Za-z0-9+/]+={0,2}$')


def main():
	try:
		sshkey = sys.stdin.readline().rstrip()
		if not valid_key.match(sshkey):
			sys.exit(1)

		with model_server.rpc_connect("repos", "read") as client:
			user_id = client.get_user_id_from_public_key(sshkey)

		if user_id:
			sys.stdout.write(FORCED_COMMAND % (GITSERVE, user_id))
			sys.exit(0)
		else:
			sys.exit(1)
	except SystemExit as e:
		sys.exit(e)
	except:
		sys.exit(1)


if __name__ == '__main__':
	main()
