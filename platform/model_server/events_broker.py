from kombu.entity import Exchange, Queue


class EventsBroker(object):
	events_exchange = Exchange("events", "direct", durable=False)

	def __init__(self, channel):
		self.channel = channel

	def subscribe(self, event, queue_name=None, callback=None):
		if queue_name:
			subscriber_queue = Queue(queue_name, exchange=self.events_exchange, routing_key=event, durable=False)
		else:
			subscriber_queue = Queue(exchange=self.events_exchange, routing_key=event, exclusive=True, durable=False)
		return self.channel.Consumer(queues=subscriber_queue, callbacks=[callback])

	def publish(self, event, msg):
		"""Publishes a message to a specific event channel.

		:param event: The event channel to publish msg to.
		:param msg: The msg we are publishing to the channel.
		"""
		producer = self.channel.Producer(serializer="msgpack")
		producer.publish(msg,
			routing_key=event,
			exchange=self.events_exchange,
			delivery_mode=2
		)
