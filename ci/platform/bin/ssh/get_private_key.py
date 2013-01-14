#!/usr/bin/python
import os
import sys

private_key = os.path.abspath(os.environ['GIT_DIR']) + '.id_rsa'
os.execlp('ssh', 'ssh', '-i', private_key, *sys.argv[1:])
