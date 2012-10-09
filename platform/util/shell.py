import os
import re

from model_server import ModelServer
from repo.store import FileSystemRepositoryStore
from util import repositories
from util.permissions import RepositoryPermissions

REPO_PATH_PATTERN = r"[^ \t\n\r\f\v']*\.git"


class RestrictedGitShell(object):
	GIT_COMMAND_ARGS = 3

	def __init__(self, commands_to_permissions, user_id_commands):
		assert isinstance(commands_to_permissions, dict)
		self.commands_to_permissions = commands_to_permissions
		self.user_id_commands = user_id_commands

	def _create_ssh_exec_args(self, route, command, path, user_id):
		uri = "git@%s" % route
		path = "'%s'" % path
		command_parts = [command, path, user_id] if command in self.user_id_commands else [command, path]
		full_command = ' '.join(command_parts)
		return "ssh", uri, full_command

	def _replace_paths(self, orig_args_str, new_path):
		return re.sub(REPO_PATH_PATTERN, new_path, orig_args_str)

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def verify_user_permissions(self, command, user_id, repo_hash):
		with ModelServer.rpc_connect("repo", "read") as client:
			permissions = client.get_permissions(user_id, repo_hash)
		if not RepositoryPermissions.has_permissions(permissions, self.commands_to_permissions[command]):
			raise InvalidPermissionError("User %s does not have the necessary permissions to run %s on repository %s" % (user_id, command, repo_hash))

	def _validify(self, repo_path):
		if not repo_path.endswith(".git"):
			raise MalformedCommandError('repo_path: %s. Repositories must end in ".git".' % repo_path)
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	def new_sshargs(self, command, repo_path, user_id):
		self._validify(repo_path)
		requested_repo_uri = self._get_requested_repo_uri(repo_path)

		with ModelServer.rpc_connect("repo", "read") as modelserver_rpc_conn:
			route, repo_hash, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
		remote_filesystem_path = repositories.to_path(repo_hash, repo_name, FileSystemRepositoryStore.DIR_LEVELS)

		self.verify_user_permissions(command, user_id, repo_hash)

		return self._create_ssh_exec_args(route, command, remote_filesystem_path, user_id)

	def handle_command(self, full_ssh_command):
		command_parts = full_ssh_command.split()
		if not len(command_parts) == self.GIT_COMMAND_ARGS:
			raise InvalidCommandError(full_ssh_command)

		command, repo_path, user_id = command_parts
		if command in self.commands_to_permissions:
			args = self.new_sshargs(command, repo_path.strip("'"), user_id)
			os.execl(*args)
		else:
			raise InvalidCommandError(command)


class InvalidCommandError(Exception):
	def __init__(self, command):
		super(InvalidCommandError, self).__init__(
			'"%s" cannot be executed in this restricted shell.' % command)

class MalformedCommandError(Exception):
	pass

class InvalidPermissionError(Exception):
	pass