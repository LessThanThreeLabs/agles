#!/usr/bin/python

"""gitserve - Similar to git-shell. A custom git command execution
environment that restricts the shell user to only git commands and
replaces certain commands with other actions."""

import os
import sys

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
	command = os.environ["SSH_ORIGINAL_COMMAND"] + ' ' + user_id
	rsh = RestrictedGitShell(commands_to_permissions, user_id_commands)
	rsh.handle_command(command)
	

if __name__ == "__main__":
	main()