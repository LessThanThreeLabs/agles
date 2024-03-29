"""server.py - Implementation of a python RPC server for BunnyRPC

BunnyRPC is an rpc framework written on top of rabbitmq.

Protocol Definition:
	client->server rpc call:
		An rpc call is of the format:
			{"method": "method", "args": [arg0, arg1, arg2, ...]}

	server->client response:
		The server's response is of the format:
			{
			"error": {
					"type": "type",
					"message": "msg",
					"traceback": "traceback"
					} or None,
			"value": value
			}
"""
from util import greenlets

import sys
import traceback

import amqp
import eventlet

from kombu.connection import Connection
from kombu.entity import Exchange, Queue
from settings.rabbit import RabbitSettings


class Server(object):
	"""RPC Server that handles rpc calls from clients.

	RPC Servers are created in the following fashion:

				server = Server(BaseInstance())
				queues_to_receive_calls_on = ["queue0", "queue1"]
				server.bind("rpc_exchange", queues_to_receive_calls_on)
				server.run()
	"""

	@property
	def deadletter_exchange_name(self):
		assert self.exchange_name is not None
		return "%s_dlx" % self.exchange_name

	def __init__(self, base_instance):
		"""Creates an RPC server that exposes <base_instance> methods to clients.

		:param base_instance: An instance of the class being exposed as an RPC
								server.
		"""
		self.base_instance = base_instance
		self.exchange_name = None
		self.queue_names = None
		self.chan = None

	def bind(self, exchange_name, queue_names, channel=None, message_ttl=10000, auto_delete=False, response_lock=None):
		""" Binds this RPC server to listen for calls from <exchange_name>
		routed to <queue_names>.

		:param exchange_name: The name of the exchange to bind this server to.
								This is the exchange we'll be receiving rpc calls from.
		:param queue_names: A list of queues we bind to. These queues are the
							the ones we pull our rpc calls from.
		"""
		assert isinstance(exchange_name, str)
		assert isinstance(queue_names, list)

		self.response_lock = eventlet.semaphore.Semaphore() if response_lock is None else response_lock

		self.exchange_name = exchange_name
		self.queue_names = set(queue_names)
		self.message_ttl = message_ttl
		if channel:
			self.channel = channel
		else:
			connection = Connection(RabbitSettings.kombu_connection_info)
			self.channel = connection.channel()
		self.consumer = self.channel.Consumer(
			callbacks=[self._handle_call],
			on_decode_error=self._on_decode_error)
		self.producer = self.channel.Producer(serializer="msgpack")

		self.exchange = Exchange(self.exchange_name, "direct", durable=False)
		self.deadletter_exchange = Exchange(self.deadletter_exchange_name,
			"fanout", channel=self.channel, durable=False)
		self.deadletter_exchange.declare()

		def setup_queue(queue_name):
			queue = Queue(queue_name, exchange=self.exchange, routing_key=queue_name,
				durable=False, auto_delete=auto_delete, queue_arguments={
					"x-dead-letter-exchange": self.deadletter_exchange_name,
					"x-message-ttl": self.message_ttl
				})
			self.consumer.add_queue(queue)

		map(setup_queue, self.queue_names)
		self.consumer.consume()

	def _on_decode_error(self, message, exc):
		self._respond(message, {
			'value': None,
			'error': {
				'type': type(exc).__name__,
				'message': str(exc),
				'traceback': ''
			}
		})

	@greenlets.spawn_wrap
	def _handle_call(self, body, message):
		message_proto = self._call(body["method"], body["args"])
		self._respond(message, message_proto)

	def _respond(self, message, response):
		correlation_id = message.properties.get("correlation_id")

		with self.response_lock:
			try:
				self.producer.publish(response,
					routing_key=message.properties["reply_to"],
					correlation_id=correlation_id,
					delivery_mode=2
				)
				message.channel.basic_ack(delivery_tag=message.delivery_tag)
			except amqp.exceptions.RecoverableConnectionError:
				pass  # This will only happen if we cleanly closed the connection already, like in tests

	def _call(self, method_name, args):
		proto = {}
		try:
			proto["value"] = getattr(self.base_instance, method_name)(*args)
			proto["error"] = None
		except Exception:
			proto["value"] = None
			exc_type, exc_value, exc_traceback = sys.exc_info()
			tb = '\t' + '\n\t'.join(traceback.format_exc().splitlines())
			proto["error"] = dict(type=exc_type.__name__,
				message=str(exc_value),
				traceback=tb)
		return proto

	def run(self):
		try:
			while True:
				self.channel.connection.drain_events()
		except:
			self.channel.connection.close()
			raise
