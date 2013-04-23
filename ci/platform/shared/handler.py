# handler.py - Abstract message handlers
""" Abstract message handler and two basic extending types"""

import collections

from util import greenlets
from model_server.events_broker import EventsBroker


class MessageHandler(object):
	def bind(self, channel):
		raise NotImplementedError("Subclasses should override this!")

	def handle_message(self, body, message):
		raise NotImplementedError("Subclasses should override this!")


class QueueListener(MessageHandler):
	def __init__(self, queue):
		super(QueueListener, self).__init__()
		self.queue = queue

	def bind(self, channel):
		channel.basic_qos(0, 1, False)
		consumer = channel.Consumer(queues=self.queue, callbacks=[greenlets.spawn_wrap(self.handle_message)])
		consumer.consume()


ResourceBinding = collections.namedtuple('ResourceBinding', ['resource', 'queue_name'])


class EventSubscriber(MessageHandler):
	def __init__(self, resources):
		super(EventSubscriber, self).__init__()
		self.resources = resources

	def bind(self, channel):
		channel.basic_qos(0, 1, False)
		for rb in self.resources:
			assert isinstance(rb, ResourceBinding)
			consumer = EventsBroker(channel).subscribe(rb.resource, queue_name=rb.queue_name,
				callback=greenlets.spawn_wrap(self.handle_message))
			consumer.consume()
