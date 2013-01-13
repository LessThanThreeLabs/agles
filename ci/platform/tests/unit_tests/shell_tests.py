import unittest

from nose.tools import *
from util.permissions import RepositoryPermissions
from util.shell import *

COMMANDS_TO_PERMISSIONS = {
	'git-receive-pack': RepositoryPermissions.RW
}

USER_ID_COMMANDS = ['git-receive-pack']


class ShellTest(unittest.TestCase):
	def setUp(self):
		self.rsh = RestrictedGitShell(COMMANDS_TO_PERMISSIONS, USER_ID_COMMANDS)

	def tearDown(self):
		pass

	def test_invalid_command(self):
		assert_raises(InvalidCommandError, self.rsh.handle_command, "invalid-command")
		assert_raises(InvalidCommandError, self.rsh.handle_command,
			"invalid-command 'long/arg/in/quotes' user_id_arg")

	def test_command_mutation(self):
		requested_repo = self.rsh._get_requested_repo_uri("'schacon/simplegit-progit.git'")
		assert_equal("schacon/simplegit-progit.git", requested_repo,
			msg="Did not correctly parse requested repository from argument string")

		new_cmd_args = self.rsh._replace_paths("'schacon/simplegit-progit.git'",
			"new/path/to/repo.git")
		assert_equals("'new/path/to/repo.git'", new_cmd_args,
			 msg="Did not correctly replace paths in new command arguments")

