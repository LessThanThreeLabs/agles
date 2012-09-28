import os
import re

from model_server import ModelServer
from repo.store import FileSystemRepositoryStore
from util import repositories

REPO_PATH_PATTERN = r"[^ \t\n\r\f\v']*\.git"


class RestrictedShell(object):

	def __init__(self, valid_commands):
		self.valid_commands = set(valid_commands)

	def _exec_ssh_gitcmd(self, route, action, path):
		uri = "git@%s" % route
		command = ' '.join([action, path])
		os.execl("ssh", uri, command)

	def _replace_paths(self, orig_args_str, new_path):
		return re.sub(REPO_PATH_PATTERN, new_path, orig_args_str)

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def _get_requested_params(self, requested_repo_uri):
		modelserver_rpc_conn = ModelServer.rpc_connect("rpc-repo-read")
		route, repo_hash, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
		modelserver_rpc_conn.close()

		path = repositories.to_path(repo_hash, repo_name, FileSystemRepositoryStore.DIR_LEVELS)
		return route, path

	def handle_gitcmd(self, action, cmd_args_str):
		requested_repo_uri = self._get_requested_repo_uri(cmd_args_str)
		route, path = self._get_requested_params(requested_repo_uri)

		new_cmd_args_str = self._replace_paths(cmd_args_str, path)
		self._exec_ssh_gitcmd(route, action, new_cmd_args_str)

	def handle_command(self, command):
		args = command.split(' ')
		if args[0] in self.valid_commands:
			cmd_args_str = ' '.join(args[1:])
			self.handle_gitcmd(args[0], cmd_args_str)
		else:
			raise InvalidCommandError(command)


class InvalidCommandError(Exception):
	def __init__(self, command):
		super(InvalidCommandError, self).__init__(
			'"%s" cannot be executed in this restricted shell.' % command)
