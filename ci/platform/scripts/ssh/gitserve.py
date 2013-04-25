#!/usr/bin/env python

"""gitserve - Similar to git-shell. A custom git command execution
environment that restricts the shell user to only git commands and
replaces certain commands with other actions."""

import logging
import os
import sys

import model_server
import util.log

from util.permissions import InvalidPermissionsError
from util.shell import RestrictedGitShell, InvalidCommandError, RepositoryNotFoundError

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
			with model_server.rpc_connect("users", "read") as client:
				user_info = client.get_user_from_id(user_id)
			print >> sys.stderr, "You have been successfully authenticated as %s, but shell access is not permitted." % user_info["email"]
	except InvalidCommandError:
		print >> sys.stderr, "The attempted command is not a permitted action in this restricted shell."
	except InvalidPermissionsError:
		print >> sys.stderr, "You do not have the necessary permissions to perform this action."
	except RepositoryNotFoundError:
		print >> sys.stderr, "Repository not found. Please check your git configuration."
	except:
		util.log.configure()
		logger = logging.getLogger("gitserve")
		logger.error("Failed to process git command %s for user %s" % (os.environ.get("SSH_ORIGINAL_COMMAND", "<no command supplied>"), user_id), exc_info=True)
		print >> sys.stderr, "An error has occured. Please contact your system administrator or support for more help."


if __name__ == "__main__":
	main()
