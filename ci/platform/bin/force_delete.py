#!/usr/bin/python
import sys
from model_server import ModelServer
from util import pathgen


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	target = sys.argv[3]
	force_delete(user_id, repo_id, target)


def force_delete(user_id, repo_id, target):
	with ModelServer.rpc_connect("repos", "update", globals=globals()) as client:
		err = client.force_delete(repo_id, user_id, target)
	if err:
		print err


if __name__ == '__main__':
	main()
