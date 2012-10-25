# handler.py - Abstract message handlers
""" Abstract message handler and two basic extending types
"""
from util import greenlets
from model_server.events_broker import EventsBroker


class MessageHandler(object):
	def bind(self, channel):
		raise NotImplementedError("Subclasses should override this!")

	def handle_message(self, body, message):
		raise NotImplementedError("Subclasses should override this!")


class QueueListener(MessageHandler):
	def __init__(self, queue):
		self.queue = queue

	def bind(self, channel):
		channel.basic_qos(0, 1, False)
		consumer = channel.Consumer(queues=self.queue, callbacks=[greenlets.spawn_wrap(self.handle_message)])
		consumer.consume()


class EventSubscriber(MessageHandler):
	def __init__(self, event, queue_name=None):
		self.event = event
		self.queue_name = queue_name

	def bind(self, channel):
		channel.basic_qos(0, 1, False)
		consumer = EventsBroker(channel).subscribe(self.event, queue_name=self.queue_name,
			callback=greenlets.spawn_wrap(self.handle_message))
		consumer.consume()
