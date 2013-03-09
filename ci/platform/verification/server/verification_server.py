# verification_server.py - Responds to repo update events and verifies build correctness

"""This file contains the logic required to verify the correctness of builds.

No methods aside from run and teardown should be called directly, as the
listener thread should respond to events by running and verifying builds on
a spawned virtual machine.
"""

import eventlet

from util.greenlets import spawn_wrap
from verification.server.verification_request_handler import VerificationRequestHandler


class VerificationServer(object):
	"""Verifies correctness of builds.

	Contains and controls a virtual machine, which is used to check out,
	lint, and run tests against commits.
	"""

	def __init__(self, *verifiers):
		self.handlers = [VerificationRequestHandler(verifier) for verifier in verifiers]

	def run(self):
		[spawn_wrap(handler.run)() for handler in self.handlers]
		while True:
			eventlet.sleep()
