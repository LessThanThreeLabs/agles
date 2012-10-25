#!usr/bin/python
import re
import sys

from model_server import ModelServer

FORCED_COMMAND = 'command="gitserve.py %d",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty'
valid_key = re.compile('^ssh-(?:dss|rsa) [A-Za-z0-9+/]+$')

try:
	sshkey = sys.stdin.readline()
	if not valid_key.match(sshkey):
		sys.exit(1)

	with ModelServer.rpc_connect("repos", "read") as client:
		user_id = client.get_user_id_from_public_key(sshkey)

	if user_id:
		sys.stdout.write(FORCED_COMMAND % user_id)
		sys.exit(0)
	else:
		sys.exit(1)
except:
	sys.exit(1)
