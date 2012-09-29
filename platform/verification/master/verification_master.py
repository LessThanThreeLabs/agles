from message_driven_server import MessageDrivenServer
from verification_results_handler import VerificationResultsHandler
from repo_update_event_handler import RepoUpdateEventHandler


class VerificationMaster(MessageDrivenServer):

	def __init__(self):
		handlers = [
			VerificationResultsHandler(),
			RepoUpdateEventHandler(),
			]
		super(VerificationMaster, self).__init__(handlers)
