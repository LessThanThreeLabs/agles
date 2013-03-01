#!/usr/bin/env python
import sys

from model_server import ModelServer
from util import pathgen


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	message = sys.argv[3]
	sha = sys.argv[4]
	merge_target = sys.argv[5]
	pending_change_ref = store_pending_ref_and_trigger_build(user_id, repo_id, message, sha, merge_target)
	print pending_change_ref


def store_pending_ref_and_trigger_build(user_id, repo_id, message, sha, merge_target):
	with ModelServer.rpc_connect("changes", "create") as client:
		commit_id = client.create_commit_and_change(
			repo_id,
			user_id,
			message,
			sha,
			merge_target)["commit_id"]
	return pathgen.hidden_ref(commit_id)

if __name__ == '__main__':
	main()
