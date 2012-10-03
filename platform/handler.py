# handler.py - Implementation of message handlers
""" Contains implementation of various message
"""


class MessageHandler(object):
	def __init__(self, queue):
		self.queue = queue

	def bind(self, channel):
		consumer = channel.Consumer(queues=self.queue, callbacks=[self.handle_message])
		consumer.qos(prefetch_count=1)
		consumer.consume()

	def handle_message(self, body, message):
		raise NotImplementedError("Subclasses should override this!")
