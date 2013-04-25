#!/usr/bin/env python
import sys

import model_server

from util import pathgen


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	sys.exit(verify_repository_permissions(user_id, repo_id))


def verify_repository_permissions(user_id, repo_id):
	with model_server.rpc_connect("users", "read") as client:
		user = client.get_user_from_id(user_id)
	return _to_return_code(user)


def _to_return_code(bool):
	return 0 if bool else 1

if __name__ == '__main__':
	main()
