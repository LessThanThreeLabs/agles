#!/usr/bin/python
import os
import sys

repo_path = os.path.abspath(os.environ['GIT_DIR'])
main_repo_path = repo_path[:repo_path.rfind('.git')] + '.git'
private_key = main_repo_path + '.id_rsa'
os.execlp('ssh', 'ssh', '-i', private_key, *sys.argv[1:])
