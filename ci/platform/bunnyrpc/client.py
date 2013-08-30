""" client.py - Implementation of a python client to BunnyRPC.

See server.py for the RPC protocol definition.
"""
import sys

from kombu.connection import Connection
from kombu.entity import Exchange, Queue

from bunnyrpc.exceptions import RPCRequestError
from settings.rabbit import RabbitSettings


class ClientBase(object):
	def __enter__(self):
		return self

	def __exit__(self, type, value, traceback):
		self.close()

	def close(self):
		raise NotImplementedError("Subclasses should override this!")


class Client(ClientBase):
	"""RPC Client that invokes calls on the server.

	A globals parameter can be passed to the constructor to define the namespace
	for raising exceptions. Otherwise, it uses the client.py namespace.

	Example of common usage:
		client = Client("exchange", "queue", globals=globals())

	!!!
	WARNING: You must start your server before you bind a client to it.
			 Otherwise, exchanges and queues have not yet been declared and
			 RabbitMQ doesn't know how to handle this. Currently this manifests
			 itself as a race condition where the client hangs on Event.set().
	!!!
	"""

	@property
	def deadletter_exchange_name(self):
		assert self.exchange_name is not None
		return "%s_dlx" % self.exchange_name

	def __init__(self, exchange_name, routing_key, globals=None):
		"""Constructor that determines where rpc calls are sent.

		:param exchange_name: The exchange to send rpc calls to. Your rpc
								server must be bound to this exchange.
		:param routing_key: The routing key that defines the route the exchange
							will send your rpc calls to. This is the same as
							the queue name your rpc server is bound to.
		:param globals: The global scope to use when re-raising a remote error.
						This allows us to raise exceptions not currently
						imported in client.py's namespace.
		"""
		assert isinstance(exchange_name, str)
		assert isinstance(routing_key, str)

		super(Client, self).__init__()
		self.caller_globals_dict = globals
		self.exchange_name = exchange_name
		self.routing_key = routing_key
		self.result = None
		self.connection = None
		self.channel = None
		self.response_mq = None
		self.message_result = None
		self._connect()

	def __getattr__(self, remote_method):
		return lambda *args, **kwargs: self._remote_call(
			remote_method, *args, **kwargs)

	def _connect(self):
		self.connection = Connection(RabbitSettings.kombu_connection_info)
		self.channel = self.connection.channel()

		self.consumer = self.channel.Consumer(
			callbacks=[self._on_response],
			on_decode_error=self._on_decode_error,
			auto_declare=False)
		self.producer = self.channel.Producer(serializer="msgpack", on_return=self._on_return)

		self.exchange = Exchange(self.exchange_name,
			"direct", channel=self.channel, durable=False)
		self.deadletter_exchange = Exchange(self.deadletter_exchange_name,
			"fanout", channel=self.channel, durable=False)

		self.exchange.declare()
		self.deadletter_exchange.declare()

		self.response_mq = Queue(exchange=self.exchange, durable=False, exclusive=True, auto_delete=True, channel=self.channel)
		self.response_mq.declare()
		self.response_mq.routing_key = self.response_mq.name
		self.response_mq.queue_bind()
		self.consumer.add_queue(self.response_mq)
		self.consumer.consume()

		self.response_mq.bind_to(exchange=self.deadletter_exchange)

	def _on_response(self, body, message):
		message.ack()

		was_deadlettered = message.headers and "x-death" in message.headers
		if was_deadlettered and message.properties.get('reply_to') == self.response_mq.name:
			# Greenlets do not propogate errors to the parent, so we send it over as an Exception
			queue_result = RPCRequestError("The server failed to process your call\nBody: %s\nProperties: %s" % (body, message.properties))
		elif not was_deadlettered:
			queue_result = body
		else:  # Not my deadlettered message
			return
		self.message_result = queue_result

	def _on_decode_error(self, message, exc):
		self._on_response("decode error: %s" % message.body, message)

	def _on_return(self, *args):
		self.message_result = RPCRequestError("The request was rejected and returned without being processed.")

	def _remote_call(self, remote_method, *args, **kwargs):
		"""Calls the remote method on the server.
		NOTE: Currently does not support **kwargs"""
		assert not kwargs
		proto = dict(method=remote_method, args=args)
		self.producer.publish(proto,
			routing_key=self.routing_key,
			reply_to=self.response_mq.name,
			mandatory=True)
		while self.message_result is None:
			self.connection.drain_events()

		result = self.message_result
		self.message_result = None
		# result is an Exception if the greenlet raised. Process the result,
		# or reraise the Exception in the parent if it is an Exception
		if isinstance(result, Exception):
			raise result
		return self._process_result(result)

	def _process_result(self, proto):
		assert isinstance(proto, dict), proto

		if proto["error"]:
			assert isinstance(proto["error"], dict)
			exc_tuple = (proto["error"]["type"],
						proto["error"]["message"],
						proto["error"]["traceback"])
			eval_str = "%s(r''' %s\n RemoteTraceback (most recent call last):%s ''')" % exc_tuple
			try:
				raise eval(eval_str, self.caller_globals_dict)
			except:
				new_exc_tuple = sys.exc_info()
				if new_exc_tuple[0].__name__ == exc_tuple[0]:  # If we receive the exception we wanted, everything is good
					raise
				raise RPCRequestError(msg=eval_str)  # Otherwise, we don't know how to recreate it, so wrap the info
		else:
			return proto["value"]

	def close(self):
		"""Closes the rabbit connection and cleans up resources."""
		self.connection.close()
