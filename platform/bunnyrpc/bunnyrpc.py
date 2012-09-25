"""bunnyrpc.py - An rpc framework on top of rabbitmq

BunnyRPC is an rpc framework written on top of rabbitmq.

The protocol is quite simple. The message sent from
client->server for an rpc call is of the format:
    {"method": "method_name", "args": [arg0, arg1, arg2, ...]}
the response from server->client is of the format:
    {"error": "error_name" (or null), "value": value}
"""
import msgpack
import pika

class Client(object):
    pass

class Server(object):
    def __init__(self, base_instance):
        self.base_instance = base_instance
        self.exchange = None
        self.queue = None
        self.chan = None

    def bind(self, exchange, queue, routing_key):
        self.exchange = exchange
        self.queue = queue
        connection = pika.BlockingConnection(pika.ConnectionParameters(
            host='localhost'))
        self.chan = connection.channel()
        self.chan.exchange_declare(exchange=exchange, type="direct")
        self.chan.queue_declare(queue=queue)
        self.chan.queue_bind(exchange=exchange,
            queue=queue,
            routing_key=routing_key)

    def handle_call(self, ch, method, properties, body):
        proto = msgpack.unpackb(body)
        response = msgpack.packb(self._call(proto["method"], proto["args"]))
        self.chan.basic_public(
            exchange=self.exchange,
            routing_key=properties.reply_to,
            body=response,
            properties=pika.BasicProperties(
                delivery_mode=2,
                correlation_id=properties.correlation_id))
        ch.basic_ack(delivery_tag=method.delivery_tag)

    def _call(self, method_name, args):
        proto = {}
        try:
            proto["value"] = getattr(self.base_instance, method_name)(*args)
            proto["error"] = None
        except Exception, e:
            proto["value"] = None
            proto["error"] = str(e)
        return proto

    def run(self):
        self.chan.basic_qos(prefetch_count=1)
        self.chan.basic_consume(self.handle_call, queue=self.queue)
        self.chan.start_consuming()
