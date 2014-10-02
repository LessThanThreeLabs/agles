from nose.tools import *
from util.restricted_shell import *

from util.test import BaseUnitTest

class ShellTest(BaseUnitTest):
	def setUp(self):
		self.git_rsh = RestrictedGitShell()
		self.hg_rsh = RestrictedHgShell()

	def tearDown(self):
		pass

	def test_invalid_command(self):
		assert_raises(InvalidCommandError, self.git_rsh.handle_command, "invalid-command")
		assert_raises(InvalidCommandError, self.git_rsh.handle_command,
			"invalid-command 'long/arg/in/quotes' user_id_arg")
		assert_raises(InvalidCommandError, self.hg_rsh.handle_command, "invalid-command")
		assert_raises(InvalidCommandError, self.hg_rsh.handle_command,
			"invalid-command 'long/arg/in/quotes' user_id_arg")

	def test_command_mutation(self):
		requested_repo = self.git_rsh._get_requested_repo_uri("'schacon/simplegit-progit.git'")
		assert_equal("schacon/simplegit-progit.git", requested_repo,
			msg="Did not correctly parse requested repository from argument string")
		requested_repo = self.hg_rsh._get_requested_repo_uri("schacon/simplegit-progit")
		assert_equal("schacon/simplegit-progit", requested_repo,
			msg="Did not correctly parse requested repository from argument string")
		assert_equal(True, False)
