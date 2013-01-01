#!/usr/bin/python
import sys

from model_server import ModelServer
from util import pathgen
from util.permissions import RepositoryPermissions


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	sys.exit(verify_repository_permissions(user_id, repo_id))


def verify_repository_permissions(user_id, repo_id):
	with ModelServer.rpc_connect("repos", "read") as client:
		permissions = client.get_permissions(user_id, repo_id)
	return _to_return_code(permissions >= RepositoryPermissions.RW)


def _to_return_code(bool):
	return 0 if bool else 1

if __name__ == '__main__':
	main()
