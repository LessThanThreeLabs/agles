import hashlib
import os
import re

import model_server
import restricted_shell

from settings.store import StoreSettings
from shared.constants import VerificationUser
from util import pathgen
from util.permissions import InvalidPermissionsError
from util.restricted_shell import RestrictedShell, InvalidCommandError

REPO_PATH_PATTERN = r"[^ \t\n\r\f\v']*\.git"


class RestrictedGitShell(RestrictedShell):
	def __init__(self, valid_commands, user_id_commands):
		super(RestrictedGitShell, self).__init__(valid_commands, user_id_commands)

		self._git_command_handlers = {
			"git-receive-pack": self.handle_receive_pack,
			"git-upload-pack": self.handle_upload_pack,
			"git-show": self.handle_git_show,
		}

		self._git_command_args = {
			"git-receive-pack": 3,
			"git-upload-pack": 3,
			"git-show": 4
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

	def _validate(self, repo_path):
		if not repo_path.endswith(".git"):
			raise MalformedCommandError('repo_path: %s. Repositories must end in ".git".' % repo_path)
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	def rp_new_sshargs(self, command, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, route, repos_path, repo_id, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists(command, user_id, repo_id)

		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))
		return self._create_ssh_exec_args(route, command, remote_filesystem_path, user_id)

	def handle_receive_pack(self, requested_repo_uri, user_id):
		args = self.rp_new_sshargs("jgit receive-pack", requested_repo_uri, user_id)
		os.execlp(*args)

	def handle_upload_pack(self, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repo_attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
			if repo_attributes is None:
				raise RepositoryNotFoundError(requested_repo_uri)
			repostore_id, route, repos_path, repo_id, repo_name = repo_attributes
			forward_url = modelserver_rpc_conn.get_repo_forward_url(repo_id)

		self.verify_user_exists("jgit upload-pack", user_id, repo_id)

		if int(user_id) == VerificationUser.id:
			remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))
			args = self._create_ssh_exec_args(route, "git upload-pack", remote_filesystem_path, user_id)
		else:
			private_key = StoreSettings.ssh_private_key
			args = self._up_pullthrough_args(private_key, forward_url, user_id)
		os.execlp(*args)

	def handle_git_show(self, requested_repo_uri, show_ref_file, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, route, repos_path, repo_id, repo_name = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists("git-show", user_id, repo_id)
		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))

		uri = "git@%s" % route
		full_command = "sh -c 'cd %s && git show %s'" % (remote_filesystem_path, show_ref_file)
		os.execlp("ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command)

	def _up_pullthrough_args(self, private_key, forward_url, user_id):
		uri, path = forward_url.split(':')
		command_parts = ["git-upload-pack", path]
		full_command = ' '.join(command_parts)
		private_key_file = os.path.join('/tmp', hashlib.sha1(private_key).hexdigest())
		with open(private_key_file, 'w') as key_file:
			os.chmod(private_key_file, 0600)
			key_file.write(private_key)
		args = ["ssh", "ssh", "-oStrictHostKeyChecking=no", "-i", private_key_file, uri, full_command]
		return args

	def handle_command(self, full_ssh_command):
		command_parts = full_ssh_command.split()
		if not command_parts[0] in self.valid_commands:
			raise InvalidCommandError(command_parts[0])
		if not len(command_parts) == self._git_command_args[command_parts[0]]:
			raise InvalidCommandError(full_ssh_command)

		repo_path = command_parts[1].strip("'")  # command_parts[1] should always be a repo path in any command
		self._validate(repo_path)
		command_parts[1] = self._get_requested_repo_uri(repo_path)
		self._git_command_handlers[command_parts[0]](*command_parts[1:])
