from kombu.entity import Exchange, Queue
from util import greenlets


class EventsBroker(object):
	events_exchange = Exchange("model:events", "direct", durable=False)

	def __init__(self, channel):
		self.channel = channel

	def subscribe(self, event, queue_name=None, callback=None):
		if queue_name:
			subscriber_queue = Queue(queue_name, exchange=self.events_exchange, routing_key=event, durable=False)
		else:
			subscriber_queue = Queue(exchange=self.events_exchange, routing_key=event, exclusive=True, durable=False)
		return self.channel.Consumer(queues=subscriber_queue, callbacks=[greenlets.spawn_wrap(callback)])

	def publish(self, resource, id, type, **contents):
		"""Publishes a message to a specific event channel.

		:param resource: The event channel to publish msg to.
		:param id: The resource id for the event.
		:param type: A description of the event.
		:param contents: An implicit dictionary to send in the message under the 'contents' key.
		"""
		producer = self.channel.Producer(serializer="msgpack")
		message = {'id': id, 'type': type, 'contents': contents}
		producer.publish(message,
			routing_key=resource,
			exchange=self.events_exchange,
			delivery_mode=2
		)
