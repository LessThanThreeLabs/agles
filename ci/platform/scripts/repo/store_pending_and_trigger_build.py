#!/usr/bin/env python
import sys

import model_server

from settings.deployment import DeploymentSettings
from util import pathgen


def main():
	user_id = int(sys.argv[1])
	repo_dir = sys.argv[2]
	repo_id = pathgen.get_repo_id(repo_dir)
	message = sys.argv[3]
	sha = sys.argv[4]
	merge_target = sys.argv[5]
	base_sha = sys.argv[6] if len(sys.argv) == 7 else None
	if not DeploymentSettings.active:
		print >> sys.stderr, '\033[33;1m' + 'Koality is currently deactivated.\nYour change will not be verified.' + '\033[0m'
	pending_change_ref = store_pending_ref_and_trigger_build(user_id, repo_id, message, sha, merge_target, base_sha)
	print pending_change_ref


def store_pending_ref_and_trigger_build(user_id, repo_id, message, sha, merge_target, base_sha):
	with model_server.rpc_connect("changes", "create") as client:
		commit_id = client.create_commit_and_change(
			repo_id,
			user_id,
			message,
			sha,
			merge_target,
			base_sha)["commit_id"]
	return pathgen.hidden_ref(commit_id)

if __name__ == '__main__':
	main()
