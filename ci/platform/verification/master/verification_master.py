from shared.message_driven_server import MessageDrivenServer
from verification_results_handler import VerificationResultsHandler
from repos_update_event_handler import ReposUpdateEventHandler


class VerificationMaster(MessageDrivenServer):

	def __init__(self):
		handlers = [
			VerificationResultsHandler(),
			ReposUpdateEventHandler(),
			]
		super(VerificationMaster, self).__init__(handlers)
