#!/usr/bin/env python

"""gitserve - Similar to git-shell. A custom git command execution
environment that restricts the shell user to only git commands and
replaces certain commands with other actions."""

import logging
import os
import sys

from model_server import ModelServer
from util.permissions import InvalidPermissionsError
from util.shell import RestrictedGitShell, InvalidCommandError

valid_commands = [
	"git-receive-pack",
	"git-upload-pack",
	"git-upload-archive",
	"git-show"
]

user_id_commands = ["git-receive-pack"]


def main():
	user_id = sys.argv[1]
	try:
		if "SSH_ORIGINAL_COMMAND" in os.environ:
			command = os.environ["SSH_ORIGINAL_COMMAND"] + ' ' + user_id
			rsh = RestrictedGitShell(valid_commands, user_id_commands)
			rsh.handle_command(command)
		else:
			with ModelServer.rpc_connect("users", "read") as client:
				user_info = client.get_user_from_id(user_id)
			print "You have been successfully authenticated as %s, but shell access is not permitted." % user_info["email"]
	except InvalidCommandError:
		print "The attempted command is not a permitted action in this restricted shell."
	except InvalidPermissionsError:
		print "You do not have the necessary permissions to perform this action."
	except:
		logger = logging.getLogger("gitserve")
		logger.error("Failed to process git command %s for user %s" % (os.environ.get("SSH_ORIGINAL_COMMAND", "<no command supplied>"), user_id), exc_info=True)
		print "An error has occured. Please contact your system administrator or support for more help."


if __name__ == "__main__":
	main()
