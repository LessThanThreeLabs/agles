import hashlib
import os
import re

import model_server

from settings.store import StoreSettings
from shared.constants import VerificationUser
from util import pathgen
from util.permissions import InvalidPermissionsError


class RestrictedShell(object):
	def __init__(self, valid_commands, user_id_commands):
		self.valid_commands = valid_commands
		self.user_id_commands = user_id_commands

	def verify_user_exists(self, command, user_id, repo_id):
		with model_server.rpc_connect("users", "read") as client:
			try:
				client.get_user_from_id(user_id)
			except:
				raise InvalidPermissionsError("User %s does not have the necessary permissions to run %s on repository %d" % (user_id, command, repo_id))

	def handle_command(self, full_ssh_command):
		raise NotImplementedError("Subclasses should override this!")


class InvalidCommandError(Exception):
	def __init__(self, command):
		super(InvalidCommandError, self).__init__(
			'"%s" cannot be executed in this restricted shell.' % command)


class RepositoryNotFoundError(Exception):
	pass


class MalformedCommandError(RepositoryNotFoundError):
	pass
