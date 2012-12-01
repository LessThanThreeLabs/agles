from changes_create_event_handler import ChangesCreateEventHandler
from shared.message_driven_server import MessageDrivenServer
from verification_results_handler import VerificationResultsHandler


class VerificationMaster(MessageDrivenServer):

	def __init__(self):
		handlers = [
			VerificationResultsHandler(),
			ChangesCreateEventHandler(),
			]
		super(VerificationMaster, self).__init__(handlers)
