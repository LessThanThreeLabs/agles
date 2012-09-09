import os
import re

from database.engine import EngineFactory
from database import schema

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
	
	def _get_requested_repo(self, cmd_args_str):
		match = re.search(REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def _get_requested_params(self, requested_repos):
		conn = EngineFactory.get_connection()
		
		
		# get a db connection
		# look up mapping for requested_repo to uri
		# return new route and path
		pass

	def handle_gitcmd(self, action, cmd_args_str):
		requested_repo = self._get_requested_repo(cmd_args_str)
		route, path = self._get_request_params(requested_repo)
		
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