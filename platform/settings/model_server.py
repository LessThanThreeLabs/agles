from kombu import Exchange, Queue

exchange = Exchange("events", "direct", durable=False)
repo_update_queue = Queue("repo-update", exchange=exchange, routing_key="repo-update", durable=False)
