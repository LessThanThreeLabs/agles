import hashlib
import os
import re

import model_server

from settings.store import StoreSettings
from shared.constants import VerificationUser
from util import pathgen
from util.permissions import InvalidPermissionsError

GIT_REPO_PATH_PATTERN = r"[^\s']+\.git"
HG_REPO_PATH_PATTERN = r"[^\s']+"


class RestrictedShell(object):
	def verify_user_exists(self, command, user_id, repo_id):
		with model_server.rpc_connect("users", "read") as client:
			try:
				client.get_user_from_id(user_id)
			except:
				raise InvalidPermissionsError("User %s does not have the necessary permissions to run %s on repository %d" % (user_id, command, repo_id))

	def handle_command(self, full_ssh_command):
		raise NotImplementedError("Subclasses should override this!")


class RestrictedGitShell(RestrictedShell):
	def __init__(self):
		super(RestrictedGitShell, self).__init__()

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

		self.valid_commands = [
			"git-receive-pack",
			"git-upload-pack",
			"git-upload-archive",
			"git-show"
		]

		self.user_id_commands = ["jgit receive-pack"]

	def _create_ssh_exec_args(self, route, command, path, user_id):
		uri = "git@%s" % route
		path = "'%s'" % path
		command_parts = [command, path, user_id] if command in self.user_id_commands else [command, path]
		full_command = ' '.join(command_parts)
		return "ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(GIT_REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def _validate(self, repo_path):
		if not repo_path.endswith(".git"):
			raise MalformedCommandError('repo_path: %s. Repositories must end in ".git".' % repo_path)
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	def rp_new_sshargs(self, command, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, stored_repos_base_path, repos_path, repo_id, repo_name, repo_type = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists(command, user_id, repo_id)

		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))
		return self._create_ssh_exec_args(stored_repos_base_path, command, remote_filesystem_path, user_id)

	def handle_receive_pack(self, requested_repo_uri, user_id):
		args = self.rp_new_sshargs("jgit receive-pack", requested_repo_uri, user_id)
		os.execlp(*args)

	def handle_upload_pack(self, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repo_attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
			if repo_attributes is None:
				raise RepositoryNotFoundError(requested_repo_uri)
			repostore_id, stored_repos_base_path, repos_path, repo_id, repo_name, repo_type = repo_attributes
			forward_url = modelserver_rpc_conn.get_repo_forward_url(repo_id)

		self.verify_user_exists("jgit upload-pack", user_id, repo_id)

		if int(user_id) == VerificationUser.id:
			remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))
			args = self._create_ssh_exec_args(stored_repos_base_path, "git upload-pack", remote_filesystem_path, user_id)
		else:
			private_key = StoreSettings.ssh_private_key
			args = self._up_pullthrough_args(private_key, forward_url, user_id)
		os.execlp(*args)

	def handle_git_show(self, requested_repo_uri, show_ref_file, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, stored_repos_base_path, repos_path, repo_id, repo_name, repo_type = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists("git-show", user_id, repo_id)
		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))

		uri = "git@%s" % stored_repos_base_path
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


# TODO(andrey) Clean up this code.
class RestrictedHgShell(RestrictedShell):
	def __init__(self):
		super(RestrictedHgShell, self).__init__()

	def _create_ssh_exec_args(self, route, command, path, user_id):
		# TODO(andrey) this should be hg@ (should add hg user?)
		uri = "git@%s" % route
		path = "%s" % path
		# TODO(andrey) Refactor in some way so that you don't have to add "serve --stdio" here
		command_parts = ["USERID=" + user_id, command, path, "serve --stdio"]
		full_command = ' '.join(command_parts)
		return "ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command

	def rp_new_sshargs(self, command, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, stored_repos_base_path, repos_path, repo_id, repo_name, repo_type = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists(command, user_id, repo_id)

		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))
		return self._create_ssh_exec_args(stored_repos_base_path, command, remote_filesystem_path, user_id)

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(HG_REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def handle_push(self, requested_repo_uri, user_id):
		args = self.rp_new_sshargs("hg -R", requested_repo_uri, user_id)
		os.execlp(*args)

	def handle_show_koality(self, requested_repo_uri, user_id, sha):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, stored_repos_base_path, repos_path, repo_id, repo_name, repo_type = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists("hg show-koality", user_id, repo_id)
		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))

		yml_path = os.path.join(remote_filesystem_path, ".hg", "strip-backup", sha + "-koality.yml")
		full_command = "cat %s" % yml_path
		os.execlp("ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", full_command)

	def handle_cat_bundle(self, requested_repo_uri, user_id, sha):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			repostore_id, stored_repos_base_path, repos_path, repo_id, repo_name, repo_type = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		self.verify_user_exists("hg cat-bundle", user_id, repo_id)
		remote_filesystem_path = os.path.join(repos_path, pathgen.to_path(repo_id, repo_name))

		bundle_path = os.path.join(remote_filesystem_path, ".hg", "strip-backup", sha + ".hg")
		full_command = "cat %s | base64" % bundle_path
		os.execlp("ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", full_command)

	def _validate(self, repo_path):
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	# TODO(andrey) modularize this function
	def handle_command(self, full_ssh_command):
		if command_parts.len() < 4:
			raise InvalidCommandError(full_ssh_command)

		command_parts = full_ssh_command.split()

		repo_path = command_parts[2]
		self._validate(repo_path)
		repo_path = self._get_requested_repo_uri(repo_path)

		if command_parts[:2] == ['hg', '-R'] and command_parts[3:5] == ['serve', '--stdio']:
			self.handle_push(repo_path, command_parts[5])
		elif command_parts[:2] == ['hg', 'show-koality']:
			self.handle_show(repo_path, command_parts[3], command_parts[2])
		elif command_parts[:2] == ['hg', 'cat-bundle']:
			self.handle_cat_bundle(repo_path, command_parts[3], command_parts[2])
		else:
			raise InvalidCommandError(full_ssh_command)


class InvalidCommandError(Exception):
	def __init__(self, command):
		super(InvalidCommandError, self).__init__(
			'"%s" cannot be executed in this restricted shell.' % command)


class RepositoryNotFoundError(Exception):
	pass


class MalformedCommandError(RepositoryNotFoundError):
	pass
