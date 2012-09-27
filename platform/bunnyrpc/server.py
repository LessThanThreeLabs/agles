import sys
import traceback

import msgpack
import pika
from settings.rabbit import connection_parameters


class Server(object):
    def __init__(self, base_instance):
        self.base_instance = base_instance
        self.exchange_name = None
        self.queue_name = None
        self.chan = None

    def bind(self, exchange_name, queue_name, routing_key):
        self.exchange_name = exchange_name
        self.queue_name = queue_name
        connection = pika.BlockingConnection(connection_parameters)
        self.chan = connection.channel()
        self.chan.exchange_declare(exchange=exchange_name, type="direct")
        self.chan.queue_declare(queue=queue_name)
        self.chan.queue_bind(exchange=exchange_name,
            queue=queue_name,
            routing_key=routing_key)

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
        self.chan.basic_consume(self.handle_call, queue=self.queue_name)
        self.chan.start_consuming()