from verification.shared.build_core import VagrantBuildCore


class BuildVerifier(VagrantBuildCore):
	def setup(self):
		self.vagrant_wrapper.spawn()

	def teardown(self):
		self.vagrant_wrapper.teardown()

	def verify(self, repo_uri, refs, callback, console_appender=None):
		"""Runs verification on a desired git commit"""
		try:
			verification_config = self.setup_build(repo_uri, refs, console_appender)
			self.run_compile_step(verification_config.compile_commands, console_appender)
			self.run_test_step(verification_config.test_commands, console_appender)
		except Exception, e:
			self.mark_failure(callback)
		else:
			self.mark_success(callback)

	def run_compile_step(self, compile_commands, console_appender):
		for compile_command in compile_commands:
			self.run_compile_command(compile_command, console_appender)

	def run_test_step(self, test_commands, console_appender):
		for test_command in test_commands:
			self.run_test_command(test_command, console_appender)
