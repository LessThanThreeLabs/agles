import hashlib
import os
import re

import model_server
import pipes

from settings.store import StoreSettings
from shared.constants import VerificationUser
from util import pathgen
from util.permissions import InvalidPermissionsError
from virtual_machine.ec2 import Ec2Vm

GIT_REPO_PATH_PATTERN = r"[^\s']+\.git"
HG_REPO_PATH_PATTERN = r"[^\s']+"


class RestrictedShell(object):
	def verify_user_exists(self, command, user_id, repo_id=None):
		with model_server.rpc_connect("users", "read") as client:
			try:
				client.get_user_from_id(user_id)
			except:
				raise InvalidPermissionsError("User %s does not have the necessary permissions to run %s on repository %d" % (user_id, command, repo_id))

	def handle_command(self, full_ssh_command):
		raise NotImplementedError("Subclasses should override this!")


class RestrictedSSHForwardingShell(RestrictedShell):
	def __init__(self):
		super(RestrictedSSHForwardingShell, self).__init__()

	#TODO (andrey) only allow people to ssh to verification (same for hg and git)
	def handle_command(self, full_ssh_command):
		command_parts = full_ssh_command.split()
		if not len(command_parts) == 3:
			raise InvalidCommandError(full_ssh_command)

		vm_instance_id = command_parts[1]
		user_id = command_parts[2]

		self.verify_user_exists("", user_id)

		with model_server.rpc_connect("debug_instances", "read") as debug_read_rpc:
			vm = debug_read_rpc.get_vm_from_instance_id(vm_instance_id)

		if vm is None:
			raise VirtualMachineNotFoundError(vm_instance_id)

		virtual_machine = Ec2Vm.from_vm_id(vm['pool_id'], vm['pool_slot'])

		if virtual_machine is None or virtual_machine.instance.id != vm_instance_id:
			raise VirtualMachineNotFoundError(vm_instance_id)

		ssh_args = virtual_machine.ssh_args().to_arg_list()
		os.execlp(ssh_args[0], *ssh_args)

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
		path = pipes.quote(path)
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
			attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		if attributes is None:
			raise RepositoryNotFoundError(requested_repo_uri)

		self.verify_user_exists(command, user_id, attributes['repo']['id'])

		remote_filesystem_path = os.path.join(attributes['repostore']['repositories_path'], pathgen.to_path(attributes['repo']['id'], attributes['repo']['name'] + '.git'))
		return self._create_ssh_exec_args(attributes['repostore']['ip_address'], command, remote_filesystem_path, user_id)

	def handle_receive_pack(self, requested_repo_uri, user_id):
		args = self.rp_new_sshargs("jgit receive-pack", requested_repo_uri, user_id)
		os.execlp(*args)

	def handle_upload_pack(self, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)
			if attributes is None:
				raise RepositoryNotFoundError(requested_repo_uri)

		self.verify_user_exists("git upload-pack", user_id, attributes['repo']['id'])

		if int(user_id) == VerificationUser.id:
			remote_filesystem_path = os.path.join(attributes['repostore']['repositories_path'], pathgen.to_path(attributes['repo']['id'], attributes['repo']['name'] + '.git'))
			args = self._create_ssh_exec_args(attributes['repostore']['ip_address'], "git upload-pack", remote_filesystem_path, user_id)
		else:
			private_key = StoreSettings.ssh_private_key
			args = self._up_pullthrough_args(private_key, attributes['repo']['forward_url'], user_id)
		os.execlp(*args)

	def handle_git_show(self, requested_repo_uri, show_ref_file, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		if attributes is None:
			raise RepositoryNotFoundError(requested_repo_uri)

		self.verify_user_exists("git-show", user_id, attributes['repo']['id'])
		remote_filesystem_path = os.path.join(attributes['repostore']['repositories_path'], pathgen.to_path(attributes['repo']['id'], attributes['repo']['name'] + '.git'))

		uri = "git@%s" % attributes['repostore']['ip_address']
		full_command = "sh -c %s" % pipes.quote("cd %s && git show %s" % (remote_filesystem_path, show_ref_file))
		os.execlp("ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command)

	def _up_pullthrough_args(self, private_key, forward_url, user_id):
		uri, path = forward_url.split(':')
		command_parts = ["git-upload-pack", "'%s'" % path]
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
		if not repo_path.endswith('.git'):
			repo_path += '.git'
		self._validate(repo_path)
		command_parts[1] = self._get_requested_repo_uri(repo_path)
		self._git_command_handlers[command_parts[0]](*command_parts[1:])


class RestrictedHgShell(RestrictedShell):
	def __init__(self):
		super(RestrictedHgShell, self).__init__()

	def _create_ssh_exec_args(self, route, command, path, user_id):
		uri = "git@%s" % route
		path = "%s" % path
		command_parts = ["USERID=" + user_id, command, path, "serve --stdio"]
		full_command = ' '.join(command_parts)
		return "ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command

	def rp_new_sshargs(self, command, requested_repo_uri, user_id):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		if attributes is None:
			raise RepositoryNotFoundError(requested_repo_uri)

		self.verify_user_exists(command, user_id, attributes['repo']['id'])

		remote_filesystem_path = os.path.join(attributes['repostore']['repositories_path'], pathgen.to_path(attributes['repo']['id'], attributes['repo']['name']))
		return self._create_ssh_exec_args(attributes['repostore']['ip_address'], command, remote_filesystem_path, user_id)

	def _get_requested_repo_uri(self, cmd_args_str):
		match = re.search(HG_REPO_PATH_PATTERN, cmd_args_str)
		assert match is not None
		return match.group()

	def handle_push(self, requested_repo_uri, user_id):
		args = self.rp_new_sshargs("hg -R", requested_repo_uri, user_id)
		os.execlp(*args)

	# TODO(andrey) refactor this and cat-bundle
	def handle_show_koality(self, requested_repo_uri, user_id, sha, file_name):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		if attributes is None:
			raise RepositoryNotFoundError(requested_repo_uri)

		self.verify_user_exists("git-show", user_id, attributes['repo']['id'])
		remote_filesystem_path = os.path.join(attributes['repostore']['repositories_path'], pathgen.to_path(attributes['repo']['id'], attributes['repo']['name']))

		bundle_path = os.path.join(remote_filesystem_path, ".hg", "strip-backup", sha + ".hg")
		uri = "git@%s" % attributes['repostore']['ip_address']
		full_command = "sh -c %s" % pipes.quote("cd %s && hg -R %s cat -r tip %s" % (remote_filesystem_path, bundle_path, file_name))
		os.execlp("ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command)

	def handle_cat_bundle(self, requested_repo_uri, user_id, sha):
		with model_server.rpc_connect("repos", "read") as modelserver_rpc_conn:
			attributes = modelserver_rpc_conn.get_repo_attributes(requested_repo_uri)

		if attributes is None:
			raise RepositoryNotFoundError(requested_repo_uri)

		self.verify_user_exists("git-show", user_id, attributes['repo']['id'])
		remote_filesystem_path = os.path.join(attributes['repostore']['repositories_path'], pathgen.to_path(attributes['repo']['id'], attributes['repo']['name']))

		bundle_path = os.path.join(remote_filesystem_path, ".hg", "strip-backup", sha + ".hg")
		uri = "git@%s" % attributes['repostore']['ip_address']
		full_command = "sh -c %s" % pipes.quote("cat %s | base64" % bundle_path)
		os.execlp("ssh", "ssh", "-p", "2222", "-oStrictHostKeyChecking=no", uri, full_command)

	def _validate(self, repo_path):
		if ".." in repo_path:
			raise MalformedCommandError('repo_path: %s. Repository path cannot contain "..".' % repo_path)

	def handle_command(self, full_ssh_command):
		command_parts = full_ssh_command.split()
		if len(command_parts) < 4:
			raise InvalidCommandError(full_ssh_command)

		repo_path = command_parts[2]
		self._validate(repo_path)
		repo_path = self._get_requested_repo_uri(repo_path)

		if command_parts[:2] == ['hg', '-R'] and command_parts[3:5] == ['serve', '--stdio']:
			self.handle_push(repo_path, command_parts[5])
		elif command_parts[:2] == ['hg', 'show-koality']:
			self.handle_show_koality(repo_path, command_parts[5], command_parts[3], command_parts[4])
		elif command_parts[:2] == ['hg', 'cat-bundle']:
			self.handle_cat_bundle(repo_path, command_parts[4], command_parts[3])
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


class VirtualMachineNotFoundError(Exception):
	pass
