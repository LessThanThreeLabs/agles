#!/usr/bin/python

"""gitserve - Similar to git-shell. A custom git command execution
environment that restricts the shell user to only git commands and
replaces certain commands with other actions."""

import os
import re
import sys

from util.shell import RestrictedShell

valid_commands = ["git-receive-pack", "git-upload-pack", "git-upload-archive"]
user_id_required_commands =["git-receive-pack"]

def main():
	user_id = sys.argv[1]
	command = os.environ["SSH_ORIGINAL_COMMAND"]
	if any(map(lambda x: command.startswith(x), user_id_required_commands)):
		command += ' ' + user_id
	rsh = RestrictedShell(valid_commands)
	rsh.handle_command(command)
	

if __name__ == "__main__":
	main()