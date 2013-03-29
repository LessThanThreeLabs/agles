import eventlet

from kombu.connection import Connection

from settings.rabbit import RabbitSettings


class MessageDrivenServer(object):
	"""A Message-driven server.

	Effectively a collection of handlers to connect to a single channel.
	"""

	def __init__(self, handlers):
		self.handlers = handlers

	def run(self):
		connection = Connection(RabbitSettings.kombu_connection_info)
		self._bind_handlers(connection)
		ioloop_greenlet = eventlet.spawn(self._ioloop, connection)
		ioloop_greenlet.link(lambda greenlet: connection.close())
		return ioloop_greenlet

	def _bind_handlers(self, connection):
		with connection.channel() as channel:
			for handler in self.handlers:
				handler.bind(channel)

	def _ioloop(self, connection):
		while True:
			connection.drain_events()
