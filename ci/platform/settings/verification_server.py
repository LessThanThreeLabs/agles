from kombu.entity import Exchange, Queue

from settings import Settings


class VerificationServerSettings(Settings):
	def __init__(self):
		super(VerificationServerSettings, self).__init__(
			__file__,
			exchange=Exchange("verification", "direct", durable=True),
			local_box_name="precise64_verification")
		self.add_values(
			verification_worker_queue=Queue("verification:worker", exchange=self.exchange, routing_key="verification:request", durable=False),
			verification_results_queue=Queue("verification:results", exchange=self.exchange, routing_key="verification:results", durable=False))

VerificationServerSettings.initialize()
