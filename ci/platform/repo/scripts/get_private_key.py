#!/usr/bin/python
import os
import sys

repo_path = os.getcwd()
main_repo_path = repo_path[:repo_path.rfind('.git')] + '.git'
private_key = main_repo_path + '.id_rsa'
os.execlp('ssh', 'ssh', '-i', private_key, *sys.argv[1:])
