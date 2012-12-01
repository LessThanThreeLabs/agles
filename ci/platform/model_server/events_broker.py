import time

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

	def publish(self, event, **contents):
		"""Publishes a message to a specific event channel.

		:param event: The event channel to publish msg to.
		:param contents: An implicit dictionary to send in the message under the 'contents' key.
		"""
		producer = self.channel.Producer(serializer="msgpack")
		message = {'timestamp': int(time.time()), 'contents': contents}
		producer.publish(message,
			routing_key=event,
			exchange=self.events_exchange,
			delivery_mode=2
		)


def get_event(noun, verb):
	return "%s.%s" % (noun, verb)
