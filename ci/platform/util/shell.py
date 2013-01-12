import os
import re

from model_server import ModelServer
from util import pathgen
from util.permissions import RepositoryPermissions, InvalidPermissionsError

REPO_PATH_PATTERN = r"[^ \t\n\r\f\v']*\.git"


class RestrictedGitShell(object):
	GIT_COMMAND_ARGS = 3

	def __init__(self, commands_to_permissions, user_id_commands):
		assert isinstance(commands_to_permissions, dict)
		self.commands_to_permissions = commands_to_permissions
		self.user_id_commands = user_id_commands

		self._git_command_handlers = {
			"git-receive-pack": self.handle_receive_pack,
			"git-upload-pack": self.handle_upload_pack,
		}

	def _create_ssh_exec_args(self, route, command, path, user_id):
		uri = "git@%s" % route
		path = "'%s'" % path
		command_parts = [command, path, user_id] if command in self.user_id_commands else [command, path]
		full_command = ' '.join(command_parts)
		return "ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def verify_user_permissions(self, command, user_id, repo_id):
		with ModelServer.rpc_connect("repos", "read") as client:
			permissions = client.get_permissions(int(user_id), repo_id)
		if not RepositoryPermissions.has_permissions(permissions, self.commands_to_permissions[command]):
			raise InvalidPermissionsError("User %s does not have the necessary permissions to run %s on repository %d" % (user_id, command, repo_id))

	def _validate(self, repo_path):
		if not repo_path.endswith(".git"):
			raise MalformedCommandError('repo_path: %s. Repositories must end in ".git".' % repo_path)
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	def rp_new_sshargs(self, command, requested_repo_uri, user_id):
		with ModelServer.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, route, repos_path, repo_id, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))

		self.verify_user_permissions(command, user_id, repo_id)

		return self._create_ssh_exec_args(route, command, remote_filesystem_path, user_id)

	def handle_receive_pack(self, requested_repo_uri, user_id):
		args = self.rp_new_sshargs("git-receive-pack", requested_repo_uri, user_id)
		os.execlp(*args)

	def handle_upload_pack(self, requested_repo_uri, user_id):
		with ModelServer.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, route, repos_path, repo_id, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
			forward_url = modelserver_rpc_conn.get_repo_forward_url(repo_id)
		uri, path = forward_url.split(':')
		command_parts = ["git-upload-pack", path]
		full_command = ' '.join(command_parts)
		args = ["ssh", "ssh", "-oStrictHostKeyChecking=no", uri, full_command]
		os.execlp(*args)

	def handle_command(self, full_ssh_command):
		command_parts = full_ssh_command.split()
		if not len(command_parts) == self.GIT_COMMAND_ARGS:
			raise InvalidCommandError(full_ssh_command)

		command, repo_path, user_id = command_parts
		repo_path = repo_path.strip("'")

		if command in self.commands_to_permissions:
			self._validate(repo_path)
			requested_repo_uri = self._get_requested_repo_uri(repo_path)
			self._git_command_handlers[command](requested_repo_uri, user_id)
		else:
			raise InvalidCommandError(command)


class InvalidCommandError(Exception):
	def __init__(self, command):
		super(InvalidCommandError, self).__init__(
			'"%s" cannot be executed in this restricted shell.' % command)


class MalformedCommandError(Exception):
	pass
