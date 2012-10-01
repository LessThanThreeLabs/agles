# handler.py - Implementation of message handlers
""" Contains implementation of various message
"""
from kombu import Consumer


class MessageHandler(object):
	def __init__(self, queue):
		self.queue = queue

	def bind(self, channel):
		Consumer(channel, queues=self.queue, callbacks=[self.handle_message]).consume()

	def handle_message(self, body, message):
		raise NotImplementedError("Subclasses should override this!")
