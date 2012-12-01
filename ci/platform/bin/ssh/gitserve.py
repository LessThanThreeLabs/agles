#!/usr/bin/python

"""gitserve - Similar to git-shell. A custom git command execution
environment that restricts the shell user to only git commands and
replaces certain commands with other actions."""

import os
import sys

from model_server import ModelServer
from util.permissions import RepositoryPermissions
from util.shell import RestrictedGitShell

commands_to_permissions = {
	"git-receive-pack": RepositoryPermissions.RW,
	"git-upload-pack": RepositoryPermissions.R,
	"git-upload-archive": RepositoryPermissions.R
}

user_id_commands = ["git-receive-pack"]

def main():
	user_id = sys.argv[1]
	if "SSH_ORIGINAL_COMMAND" in os.environ:
		command = os.environ["SSH_ORIGINAL_COMMAND"] + ' ' + user_id
		rsh = RestrictedGitShell(commands_to_permissions, user_id_commands)
		rsh.handle_command(command)
	else:
		with ModelServer.rpc_connect("users", "read") as client:
			user_info = client.get_user_from_id(user_id)
		print "You have been successfully authenticated as %s, but shell access is not permitted." % user_info["email"]


if __name__ == "__main__":
	main()
