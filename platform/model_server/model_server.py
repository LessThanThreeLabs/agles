# model_server.py - Defines an abstraction on top of a database that allows for event firing

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""
from kombu import Connection, Exchange, Queue

from bunnyrpc.client import Client
from build.create_handler import BuildCreateHandler
from build.read_handler import BuildReadHandler
from build.update_handler import BuildUpdateHandler
from change.create_handler import ChangeCreateHandler
from change.read_handler import ChangeReadHandler
from change.update_handler import ChangeUpdateHandler
from repo.create_handler import RepoCreateHandler
from repo.read_handler import RepoReadHandler


class ModelServer(object):
	"""A higher level abstraction on top of the database that allows for event creation on database
	actions.

	All methods in this API return low level database objects such as row_results. This is only meant
	to be a thin abstraction that allows for proxying, not for higher level modification of the DB-API.
	"""

	rpc_handler_classes = [
		BuildCreateHandler,
		BuildReadHandler,
		BuildUpdateHandler,
		ChangeCreateHandler,
		ChangeReadHandler,
		ChangeUpdateHandler,
		RepoCreateHandler,
		RepoReadHandler,
	]

	events_exchange = Exchange("events", "direct", durable=False)

	@classmethod
	def rpc_connect(cls, route_noun, route_verb):
		route = '-'.join(['rpc', route_noun, route_verb])
		return Client("model-rpc", route)

	@classmethod
	def subscribe(cls, event, channel, queue_name=None, callback=None):
		if queue_name:
			subscriber_queue = Queue(queue_name, exchange=cls.events_exchange, routing_key=event, durable=False)
		else:
			subscriber_queue = Queue(exchange=cls.events_exchange, routing_key=event, exclusive=True, durable=False)
		return channel.Consumer(queues=subscriber_queue, callbacks=[callback])
		"""No-op

		This method is a placeholder. In the future, we may implement a callback
		based method where calling subscribe on the server will actually subscribe
		you to a channel.
		"""
		raise NotImplementedError(
			"Subscription should be done by binding to the zmq address")

	@classmethod
	def publish(cls, event, msg, channel):
		"""Publishes a message to a specific event channel.

		:param event: The event channel to publish msg to.
		:param msg: The msg we are publishing to the channel.
		"""
		producer = channel.Producer(serializer="msgpack")
		producer.publish(msg,
			routing_key=event,
			exchange=cls.events_exchange,
			delivery_mode=2
		)

	def __init__(self, channel=None):
		if channel:
			self.channel = channel
		else:
			connection = Connection("amqp://guest:guest@localhost//")
			self.channel = connection.channel()

	def start(self):
		map(lambda rpc_handler_class: rpc_handler_class().get_server(self.channel),
			self.rpc_handler_classes)
		while True:
			self.channel.connection.drain_events()
