#!/usr/bin/python

"""gitserve - Similar to git-shell. A custom git command execution
environment that restricts the shell user to only git commands and
replaces certain commands with other actions."""

import os
import re
import sys

from util.shell import RestrictedShell

valid_commands = ["git-receive-pack", "git-upload-pack", "git-upload-archive"]

def main():
	user = sys.argv[0]
	command = os.environ["SSH_ORIGINAL_COMMAND"]
	rsh = RestrictedShell(valid_commands)
	rsh.handle_command(command)
	

if __name__ == "__main__":
	main()