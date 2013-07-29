import sys

import eventlet

from kombu.connection import Connection

from settings.rabbit import RabbitSettings
from util.log import Logged


class MessageDrivenServer(object):
	"""A Message-driven server.

	Effectively a collection of handlers to connect to a single channel.
	"""

	@Logged()
	def __init__(self, handlers):
		self.handlers = handlers

	def run(self):
		connection = Connection(RabbitSettings.kombu_connection_info)
		self._bind_handlers(connection)
		ioloop_greenlet = eventlet.spawn(self._ioloop, connection)
		ioloop_greenlet.link(lambda greenlet: connection.close())
		return ioloop_greenlet

	def _bind_handlers(self, connection):
		channel = connection.channel()
		for handler in self.handlers:
			handler.bind(channel)

	def _ioloop(self, connection):
		try:
			while True:
				connection.drain_events()
		except:
			exc_info = sys.exc_info()
			self.logger.critical("Server IOloop exited", exc_info=exc_info)
			raise exc_info
