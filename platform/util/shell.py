import os
import re

from model_server import ModelServer
from repo.store import FileSystemRepositoryStore
from util import repositories

REPO_PATH_PATTERN = r"[^ \t\n\r\f\v']*\.git"


class RestrictedGitShell(object):
	GIT_COMMAND_ARGS = 3

	def __init__(self, valid_commands):
		self.valid_commands = set(valid_commands)

	def _create_ssh_exec_args(self, route, command, path, user_id):
		uri = "git@%s" % route
		path = "'%s'" % path
		command = ' '.join([command, path, user_id])
		return "ssh", uri, command

	def _replace_paths(self, orig_args_str, new_path):
		return re.sub(REPO_PATH_PATTERN, new_path, orig_args_str)

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def _get_route_path(self, requested_repo_uri):
		with ModelServer.rpc_connect("repo", "read") as modelserver_rpc_conn:
			route, repo_hash, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		path = repositories.to_path(repo_hash, repo_name, FileSystemRepositoryStore.DIR_LEVELS)
		return route, path

	def validify(self, repo_path):
		if not repo_path.endswith(".git"):
			raise MalformedCommandError('repo_path: %s. Repositories must end in ".git".' % repo_path)
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	def new_sshargs(self, command, repo_path, user_id):
		self.validify(repo_path)
		requested_repo_uri = self._get_requested_repo_uri(repo_path)
		route, remote_filesystem_path = self._get_route_path(requested_repo_uri)

		#new_cmd_args_str = self._replace_paths(repo_path, remote_filesystem_path)
		return self._create_ssh_exec_args(route, command, remote_filesystem_path, user_id)#new_cmd_args_str)

	def handle_command(self, full_ssh_command):
		command_parts = full_ssh_command.split(' ')
		if not len(command_parts) == self.GIT_COMMAND_ARGS:
			raise InvalidCommandError(full_ssh_command)

		command, repo_path, user_id = command_parts
		if command in self.valid_commands:
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
