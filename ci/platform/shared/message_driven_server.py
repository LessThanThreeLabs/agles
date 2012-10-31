from kombu.connection import Connection

from settings.rabbit import connection_info


class MessageDrivenServer(object):
	"""A Message-driven server.

	Effectively a collection of handlers to connect to a single channel.
	"""

	def __init__(self, handlers):
		self.handlers = handlers

	def run(self):
		with Connection(connection_info) as connection:
			with connection.channel() as channel:
				for handler in self.handlers:
					handler.bind(channel)
				while True:
					connection.drain_events()
