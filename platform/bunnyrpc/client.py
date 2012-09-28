"""bunnyrpc.py - An rpc framework on top of rabbitmq

BunnyRPC is an rpc framework written on top of rabbitmq.

The protocol is quite simple. The message sent from
client->server for an rpc call is of the format:
    {"method": "method", "args": [arg0, arg1, arg2, ...]}
the response from server->client is of the format:
    {
    "error": {
                "type": "type",
                "message": "msg",
                "traceback": "traceback"
             } or None,
    "value": value
    }
"""
from functools import partial

import msgpack
import pika
from gevent import event, spawn, queue, monkey; monkey.patch_all(thread=False)
from settings.rabbit import connection_parameters


class ClientBase(object):
    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.close()

    def close(self):
        raise RuntimeError("Subclasses should implement this!")

class Client(ClientBase):

    def __init__(self, exchange_name, routing_key):
        self.exchange_name = exchange_name
        self.routing_key = routing_key
        self.result_queue = queue.Queue()
        self.connection_event = event.Event()
        self.connection = None
        self.channel = None
        self.ioloop_greenlet = None
        self.response_mq = None
        self._connect(self.exchange_name)

    def listen(self):
        self.connection.ioloop.start()

    def __getattr__(self, remote_method):
        return lambda *args, **kwargs: self._remote_call(
            remote_method, *args, **kwargs)

    def _connect(self, exchange):
        self.connection = pika.SelectConnection(connection_parameters,
            partial(self._on_connected, exchange))
        self.ioloop_greenlet = spawn(self.listen)
        self.connection_event.wait()

    def _on_connected(self, exchange, connection):
        connection.channel(partial(self._on_chan_open, exchange))

    def _on_chan_open(self, exchange, chan):
        self.channel = chan
        self.channel.exchange_declare(exchange=exchange, type="direct",
            callback=self._on_exchange_declare)

    def _on_exchange_declare(self, frame):
         self.channel.queue_declare(
             exclusive=True, callback=self._on_queue_declare)

    def _on_queue_declare(self, frame):
        self.response_mq = frame.method.queue
        self.channel.queue_bind(
            callback=self._on_queue_bind,
            queue=self.response_mq,
            exchange=self.exchange_name,
            routing_key=self.response_mq)

    def _on_queue_bind(self, frame):
        self.channel.basic_consume(self._on_response, queue=self.response_mq)
        self.connection_event.set()

    def _on_response(self, ch, method, props, body):
        proto = msgpack.unpackb(body)
        self.result_queue.put(proto)
        ch.basic_ack(delivery_tag=method.delivery_tag)

    def _remote_call(self, remote_method, *args, **kwargs):
        """Calls the remote method on the server.
        NOTE: Currently does not support **kwargs"""
        assert not kwargs
        proto = dict(method=remote_method, args=args)
        self.channel.basic_publish(
            exchange=self.exchange_name,
            routing_key=self.routing_key,
            properties=pika.BasicProperties(reply_to=self.response_mq),
            body=msgpack.packb(proto))
        proto = self.result_queue.get()
        return self._process_result(proto)

    def _process_result(self, proto):
        if proto["error"]:
            exc_tuple = (proto["error"]["type"],
                         proto["error"]["message"],
                         proto["error"]["traceback"])
            eval_str = "%s(r'''%s\n RemoteTraceback (most recent call last):%s''')" % exc_tuple
            raise eval(eval_str)
        else:
            return proto["value"]

    def close(self):
        self.ioloop_greenlet.kill()
        self.connection.close()
