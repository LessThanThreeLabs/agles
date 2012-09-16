from nose.tools import unittest
from nose.tools import *
from util.shell import *

VALID_COMMANDS = ['git-receive-pack']


class ShellTest(unittest.TestCase):
	def setUp(self):
		pass

	def tearDown(self):
		pass

	def test_invalid_command(self):
		rsh = RestrictedShell(VALID_COMMANDS)
		assert_raises(InvalidCommandError, rsh.handle_command, "invalid-command")
		assert_raises(InvalidCommandError, rsh.handle_command,
					  "invalid-command arg0 'long/arg/in/quotes'")

	def test_command_mutation(self):
		rsh = RestrictedShell(VALID_COMMANDS)
		requested_repo = rsh._get_requested_repo_uri("'schacon/simplegit-progit.git'")
		assert_equals("schacon/simplegit-progit.git", requested_repo,
					  msg="Did not correctly parse requested repository from argument string")

		new_cmd_args = rsh._replace_paths("'schacon/simplegit-progit.git'",
										 "new/path/to/repo.git")
		assert_equals("'new/path/to/repo.git'", new_cmd_args,
					  msg="Did not correctly replace paths in new command arguments")
