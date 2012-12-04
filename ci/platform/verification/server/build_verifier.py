from build_core import BuildCore


class BuildVerifier(BuildCore):
	def setup(self):
		self.vagrant_wrapper.spawn()

	def teardown(self):
		self.vagrant_wrapper.teardown()

	def verify(self, repo_uri, refs, callback, console_appender=None):
		"""Runs verification on a desired git commit"""
		try:
			self.checkout_refs(repo_uri, refs)
			verification_config = self.get_verification_configurations()
			self.declare_all_commands(console_appender, verification_config)
			self.setup_vagrant_wrapper(console_appender)
			self._run_compile_step(verification_config.compile_commands, console_appender)
			self._run_test_step(verification_config.test_commands, console_appender)
		except Exception, e:
			self.mark_failure(callback, e)
		else:
			self.mark_success(callback)

	def _run_compile_step(self, compile_commands, console_appender):
		for compile_command in compile_commands:
			self.run_compile_command(compile_command, console_appender)

	def _run_test_step(self, test_commands, console_appender):
		for test_command in test_commands:
			self.run_test_command(test_command, console_appender)
