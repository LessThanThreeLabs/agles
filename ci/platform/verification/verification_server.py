# verification_server.py - Responds to repo update events and verifies build correctness

"""This file contains the logic required to verify the correctness of builds.

No methods aside from run and teardown should be called directly, as the
listener thread should respond to events by running and verifying builds on
a spawned virtual machine.
"""

from shared.message_driven_server import MessageDrivenServer
from util.log import Logged


@Logged()
class VerificationServer(MessageDrivenServer):
	"""Verifies correctness of builds.

	Contains and controls a virtual machine, which is used to check out,
	lint, and run tests against commits.
	"""

	def __init__(self, change_verifier):
		handlers = [change_verifier]
		super(VerificationServer, self).__init__(handlers)
