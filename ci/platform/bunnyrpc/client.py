""" client.py - Implementation of a python client to BunnyRPC.

See server.py for the RPC protocol definition.
"""
import sys

import msgpack
import eventlet
pika = eventlet.import_patched('pika')

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
		self.ioloop_greenlet = None
		self.response_mq = None
		self._connect()

	def __getattr__(self, remote_method):
		return lambda *args, **kwargs: self._remote_call(
			remote_method, *args, **kwargs)

	def _connect(self):
		self.connection = pika.SelectConnection(RabbitSettings.pika_connection_parameters,
			self._on_connected)
		self.connection.ioloop.start()

	def _on_connected(self, connection):
		connection.channel(self._on_chan_open)

	def _on_chan_open(self, chan):
		self.channel = chan
		self.channel.add_on_return_callback(self._on_return)
		self.channel.exchange_declare(exchange=self.exchange_name,
			type="direct", callback=self._on_exchange_declare)

	def _on_exchange_declare(self, frame):
		self.channel.exchange_declare(exchange=self.deadletter_exchange_name,
			type="fanout", callback=self._on_dlx_exchange_declare)

	def _on_dlx_exchange_declare(self, frame):
		self.channel.queue_declare(
			exclusive=True,
			auto_delete=True,
			callback=self._on_queue_declare)

	def _on_queue_declare(self, frame):
		self.response_mq = frame.method.queue
		self.channel.queue_bind(
			queue=self.response_mq,
			exchange=self.deadletter_exchange_name)
		self.channel.queue_bind(
			callback=self._on_queue_bind,
			queue=self.response_mq,
			exchange=self.exchange_name,
			routing_key=self.response_mq)

	def _on_queue_bind(self, frame):
		self.channel.basic_consume(self._on_response, queue=self.response_mq)
		self.connection.ioloop.poller.open = False

	def _on_response(self, ch, method, props, body):
		ch.basic_ack(delivery_tag=method.delivery_tag)

		was_deadlettered = props.headers and "x-death" in props.headers
		if was_deadlettered and props.reply_to == self.response_mq:
			# Greenlets do not propogate errors to the parent, so we send it over as an Exception
			queue_result = RPCRequestError("The server failed to process your call\nBody: %s" % msgpack.unpackb(body))
		elif not was_deadlettered:
			queue_result = msgpack.unpackb(body)
		else:  # Not my deadlettered message
			return
		self.message_result = queue_result
		self.connection.ioloop.poller.open = False

	def _on_return(self, method, props, body):
		# Greenlets do not propogate errors to the parent, so we send it over as an Exception
		error = RPCRequestError("The request was rejected and returned without being processed.")
		self.message_result = error
		self.connection.ioloop.poller.open = False

	def _remote_call(self, remote_method, *args, **kwargs):
		"""Calls the remote method on the server.
		NOTE: Currently does not support **kwargs"""
		assert not kwargs
		proto = dict(method=remote_method, args=args)
		self.channel.basic_publish(
			exchange=self.exchange_name,
			routing_key=self.routing_key,
			properties=pika.BasicProperties(reply_to=self.response_mq,
				content_encoding="binary",
				content_type="application/x-msgpack"),
			body=msgpack.packb(proto),
			mandatory=True)
		self.connection.ioloop.poller.open = True
		self.connection.ioloop.start()
		result = self.message_result
		# result is an Exception if the greenlet raised. Process the result,
		# or reraise the Exception in the parent if it is an Exception
		if isinstance(result, Exception):
			raise result
		return self._process_result(result)

	def _process_result(self, proto):
		assert isinstance(proto, dict)

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
		self.connection.ioloop.poller.open = False
		self.connection.close()
