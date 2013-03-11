class VerifierPool(object):
	def __init__(self, spawn_method, max_verifiers, uri_translator=None):
		self.spawn_method = spawn_method
		self.max_verifiers = max_verifiers
		self.verifiers = {}
		self.uri_translator = uri_translator

	def spawn_all(self):
		for i in range(self.max_verifiers):
			if i not in self.verifiers:
				self.spawn_verifier(i)
		return self.verifiers

	def teardown(self):
		for i in self.verifiers:
			self.remove_verifier(i)

	def spawn_verifier(self, verifier_number):
		assert verifier_number not in self.verifiers
		self.verifiers[verifier_number] = self.spawn_method(verifier_number, self.uri_translator)
		return self.verifiers[verifier_number]

	def remove_verifier(self, verifier_number):
		self.verifiers[verifier_number].teardown()
		del self.verifiers[verifier_number]
