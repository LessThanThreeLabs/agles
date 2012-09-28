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
import sys
import traceback

import msgpack
import pika
from settings.rabbit import connection_parameters


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
		return "%s-dlx" % self.exchange_name

	def __init__(self, base_instance):
		"""Creates an RPC server that exposes <base_instance> methods to clients.

		:param base_instance: An instance of the class being exposed as an RPC
								server.
		"""
		self.base_instance = base_instance
		self.exchange_name = None
		self.queue_names = None
		self.chan = None

	def bind(self, exchange_name, queue_names):
		""" Binds this RPC server to listen for calls from <exchange_name>
		routed to <queue_names>.

		:param exchange_name: The name of the exchange to bind this server to.
							  This is the exchange we'll be receiving rpc calls from.
		:param queue_names: A list of queues we bind to. These queues are the
							the ones we pull our rpc calls from.
		"""
		self.exchange_name = exchange_name
		self.queue_names = set(queue_names)
		connection = pika.BlockingConnection(connection_parameters)
		self.chan = connection.channel()
		self.chan.exchange_declare(exchange=self.exchange_name, type="direct")
		self.chan.exchange_declare(exchange=self.deadletter_exchange_name,
			type="fanout")

		def setup_queue(queue_name):
			self.chan.queue_declare(
				queue=queue_name,
				arguments={
					"x-dead-letter-exchange": self.deadletter_exchange_name
				})
			self.chan.queue_bind(exchange=exchange_name,
				queue=queue_name,
				routing_key=queue_name)

		map(setup_queue, self.queue_names)

	def _handle_call(self, chan, method, properties, body):
		proto = msgpack.unpackb(body)
		message_proto = self._call(proto["method"], proto["args"])
		response = msgpack.packb(message_proto)
		self.chan.basic_publish(
			exchange=self.exchange_name,
			routing_key=properties.reply_to,
			properties=pika.BasicProperties(
				delivery_mode=2),
			body=response)
		chan.basic_ack(delivery_tag=method.delivery_tag)

	def _call(self, method_name, args):
		proto = {}
		try:
			proto["value"] = getattr(self.base_instance, method_name)(*args)
			proto["error"] = None
		except Exception, e:
			proto["value"] = None
			exc_type, exc_value, exc_traceback = sys.exc_info()
			tb = '\t' + '\n\t'.join(traceback.format_exc().splitlines())
			proto["error"] = dict(type=exc_type.__name__,
				message=str(exc_value),
				traceback=tb)
		return proto

	def run(self):
		self.chan.basic_qos(prefetch_count=1)
		for queue_name in self.queue_names:
			self.chan.basic_consume(self._handle_call, queue=queue_name)
		self.chan.start_consuming()
