from kombu.entity import Exchange, Queue

exchange = Exchange("verification", "direct", durable=True)
verification_worker_queue = Queue("verification:worker", exchange=exchange, routing_key="verification:request", durable=False)
verification_results_queue = Queue("verification:results", exchange=exchange, routing_key="verification:results", durable=False)

box_name = "precise64_verification"
