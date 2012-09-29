from kombu import Exchange, Queue

exchange = Exchange("verification", "direct", durable=False)
verification_request_queue = Queue("verification-request", exchange=exchange, routing_key="verification-request", durable=False)
verification_results_queue = Queue("verification-results", exchange=exchange, routing_key="verification-results", durable=False)
merge_queue = Queue("merge", exchange=exchange, routing_key="merge", durable=False)

box_name = "precise64_verification"
