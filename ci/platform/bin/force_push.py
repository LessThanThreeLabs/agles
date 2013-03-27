#!/usr/bin/env python
import sys

import model_server

from util import pathgen


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	from_target = sys.argv[3]
	to_target = sys.argv[4]
	force_push(user_id, repo_id, from_target, to_target)


def force_push(user_id, repo_id, from_target, to_target):
	with model_server.rpc_connect("repos", "update") as client:
		client.force_push(repo_id, user_id, from_target, to_target)

if __name__ == '__main__':
	main()
