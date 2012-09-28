import sys
import traceback

import msgpack
import pika
from settings.rabbit import connection_parameters


class Server(object):

	@property
	def deadletter_exchange_name(self):
		assert self.exchange_name is not None
		return "%s-dlx" % self.exchange_name

	def __init__(self, base_instance):
		self.base_instance = base_instance
		self.exchange_name = None
		self.queue_names = None
		self.chan = None

	def bind(self, exchange_name, queue_names, routing_key):
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
				routing_key=routing_key)

		map(setup_queue, self.queue_names)

	def handle_call(self, chan, method, properties, body):
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
			self.chan.basic_consume(self.handle_call, queue=queue_name)
		self.chan.start_consuming()
