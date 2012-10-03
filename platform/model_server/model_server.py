# model_server.py - Defines an abstraction on top of a database that allows for event firing

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""
from kombu import Connection, Exchange

from bunnyrpc.client import Client
from repo.create_handler import RepoCreateHandler
from repo.read_handler import RepoReadHandler


class ModelServer(object):
	"""A higher level abstraction on top of the database that allows for event creation on database
	actions.

	All methods in this API return low level database objects such as row_results. This is only meant
	to be a thin abstraction that allows for proxying, not for higher level modification of the DB-API.
	"""

	rpc_handler_classes = [
		RepoCreateHandler,
		RepoReadHandler,
		]

	@classmethod
	def rpc_connect(cls, route):
		return Client("model-rpc", route)

	def __init__(self, channel=None):
		if channel:
			self.channel = channel
		else:
			connection = Connection("amqp://guest:guest@localhost//")
			self.channel = connection.channel()
		self.producer = self.channel.Producer(serializer="msgpack")
		self.events_exchange = Exchange("events", "direct", durable=False)

	def start(self):
		map(lambda rpc_handler_class: rpc_handler_class().get_server(self.channel),
			self.rpc_handler_classes)
		while True:
			self.channel.connection.drain_events()

	def subscribe(self, event):
		"""No-op

		This method is a placeholder. In the future, we may implement a callback
		based method where calling subscribe on the server will actually subscribe
		you to a channel.
		"""
		raise NotImplementedError(
			"Subscription should be done by binding to the zmq address")

	def publish(self, event, msg):
		"""Publishes a message to a specific event channel.

		:param event: The event channel to publish msg to.
		:param msg: The msg we are publishing to the channel.
		"""
		self.producer.publish(msg,
			exchange=self.events_exchange,
			delivery_mode=2
		)
