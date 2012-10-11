from verification.server.verification_result import VerificationResult


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
