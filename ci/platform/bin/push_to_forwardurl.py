#!/usr/bin/env python
import sys

import model_server

from util import pathgen


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	target = sys.argv[3]
	force_push(user_id, repo_id, target)


def force_push(user_id, repo_id, message, target):
	with model_server.rpc_connect("repos", "update") as client:
		client.push_forwardurl(repo_id, user_id, target)

if __name__ == '__main__':
	main()
