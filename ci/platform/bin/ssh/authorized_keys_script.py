#!/usr/bin/env python
import os
import re
import sys

from model_server import ModelServer

GITSERVE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "gitserve.py")
FORCED_COMMAND = 'command="/etc/koality/python %s %d",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty'
valid_key = re.compile('^ssh-(?:dss|rsa) [A-Za-z0-9+/]+={0,2}$')

try:
	sshkey = sys.stdin.readline().rstrip()
	if not valid_key.match(sshkey):
		sys.exit(1)

	with ModelServer.rpc_connect("repos", "read") as client:
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
