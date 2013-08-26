from nose.tools import *
from util.test import BaseUnitTest
from virtual_machine import remote_command
from util.test import fake_build_verifier


class RemoteCommandTest(BaseUnitTest):
	def test_xunit_function_replacement(self):
		self._xunit_function_replacement_for_step({'mycommand': {'script': 'true', 'xunit': 'some/path'}})
		self._xunit_function_replacement_for_step({'mycommand': {'script': 'true', 'xunit': ['some/path', 'some/path/2']}})

	def _xunit_function_replacement_for_step(self, step):
		cmd = remote_command.RemoteTestCommand(step)
		original_get_xunit_contents = cmd.get_xunit_contents

		assert_is_not_none(cmd.xunit)
		cmd.run(fake_build_verifier.FakeVirtualMachine(0))

		assert_not_equal(original_get_xunit_contents, cmd.get_xunit_contents)

		assert_true(False)
