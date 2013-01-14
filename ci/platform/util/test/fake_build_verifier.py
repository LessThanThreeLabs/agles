from verification.shared.verification_config import VerificationConfig
from verification.shared.verification_result import VerificationResult


class FakeBuildVerifier(object):
	def __init__(self, passes):
		self.passes = passes

	def setup(self):
		pass

	def teardown(self):
		pass

	def verify(self, repo_uri, refs, callback, console_appender=None):
		if self.passes:
			callback(VerificationResult.SUCCESS)
		else:
			callback(VerificationResult.FAILURE)

	def setup_build(self, repo_uri, refs, private_key, console_appender=None):
		return VerificationConfig(None, None)

	def declare_commands(self, console_appender, console_type, commands):
		pass

	def run_compile_step(self, compile_commands, console_appender=None):
		pass

	def run_test_command(self, test_command, console_appender=None):
		if not self.passes:
			raise Exception()

	def mark_success(self, callback):
		callback(VerificationResult.SUCCESS)

	def mark_failure(self, callback):
		callback(VerificationResult.FAILURE)
