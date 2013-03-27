from kombu.entity import Exchange, Queue

from database_backed_settings import DatabaseBackedSettings


class VerificationServerSettings(DatabaseBackedSettings):
	def __init__(self):
		super(VerificationServerSettings, self).__init__(
			exchange=Exchange("verification", "direct", durable=True),
			virtual_machine_count=1,
			static_pool_size=1,
			local_box_name="precise64_verification")
		self.add_values(
			verification_worker_queue=Queue("verification:worker", exchange=VerificationServerSettings.exchange, routing_key="verification:request", durable=False),
			verification_results_queue=Queue("verification:results", exchange=VerificationServerSettings.exchange, routing_key="verification:results", durable=False))
