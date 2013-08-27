import string
import random

from eventlet.event import Event

from nose.tools import *

from bunnyrpc.client import Client, RPCRequestError
from bunnyrpc.server import Server
from kombu.connection import Connection
from kombu.entity import Queue
from settings.rabbit import RabbitSettings
from util.test import BaseIntegrationTest
from util.test.mixins import RabbitMixin, GreenProcess


class BunnyRPCTest(BaseIntegrationTest, RabbitMixin):
	@classmethod
	def setup_class(cls):
		super(BunnyRPCTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(BunnyRPCTest, self).setUp()

		ttl_event = Event()
		self.ttl_process = GreenProcess(target=self._runserver,
			args=[self._TestRPCServer(), "ttl_exchange", ["stale_queue"], ttl_event],
			kwargs=dict(ttl=1, auto_delete=False))
		self.ttl_process.start()

		server_event = Event()
		self.server_process = GreenProcess(target=self._runserver,
			args=[self._TestRPCServer(), "exchange", ["queue0", "queue1"], server_event])
		self.server_process.start()

		return_event = Event()
		self.returned_msg_process = GreenProcess(target=self._runserver,
			args=[self._TestRPCServer(), "returned_exchange", [], return_event])
		self.returned_msg_process.start()

		ttl_event.wait()
		self.ttl_process.terminate()
		server_event.wait()
		return_event.wait()

	def tearDown(self):
		super(BunnyRPCTest, self).tearDown()
		self.server_process.terminate()
		self.returned_msg_process.terminate()
		self._purge_queues()
		with Connection(RabbitSettings.kombu_connection_info) as connection:
			Queue("stale_queue")(connection).delete()

	def _runserver(self, base_instance, exchange,
					queue_names, event, ttl=1000, auto_delete=True):
		server = Server(base_instance)
		server.bind(exchange, queue_names, message_ttl=ttl, auto_delete=auto_delete)
		event.send()
		server.run()

	def test_basic_clientserver_rpc(self):
		with Client("exchange", "queue0") as client:
			for i in xrange(1, 10):
				server_count = client.incr()
				assert_equal(server_count, i)

	def test_exceptional_controlflow_rpc(self):
		with Client("exchange", "queue0", globals=globals()) as client:
			assert_raises(ZeroDivisionError, client.div, 6, 0)
			assert_raises(MyError, client.raise_my_error)
			assert_raises(RPCRequestError, client.raise_special_error)

	def _run_multiclients_in_tandem(self, client0, client1):
		try:
			for i in xrange(1, 10):
				client = client0 if i % 2 == 0 else client1
				server_count = client.incr()
				assert_equal(server_count, i)
		finally:
			client0.close()
			client1.close()

	def test_multiclient_singlequeue(self):
		client0 = Client("exchange", "queue0")
		client1 = Client("exchange", "queue0")
		self._run_multiclients_in_tandem(client0, client1)

	def test_multiclient_multiqueue(self):
		client0 = Client("exchange", "queue0")
		client1 = Client("exchange", "queue1")
		self._run_multiclients_in_tandem(client0, client1)

	def test_deadlettering_nonexistent_queue(self):
		with Client("ttl_exchange", "nonexistent_queue") as client:
			assert_raises(RPCRequestError, client.incr)

	def test_deadlettering_stale_queue(self):
		with Client("ttl_exchange", "stale_queue") as client:
			assert_raises(RPCRequestError, client.incr)

	def test_returned_message(self):
		with Client("returned_exchange", "queue") as client:
			assert_raises(RPCRequestError, client.incr)

	def test_large_message_stress(self):
		with Client("exchange", "queue0") as client:
			for message in xrange(50):
				s = string.ascii_letters * 10000 * message
				assert_equal(len(s), len(client.return_string(s)))

	def test_high_volume_stress(self):
		with Client("exchange", "queue0") as client:
			for message in xrange(10000):
				s = string.ascii_letters * message
				assert_equal(len(s), len(client.return_string(s)))

	class _TestRPCServer(object):
		def __init__(self):
			self.count = 0

		def incr(self):
			self.count += 1
			return self.count

		def div(self, a, b):
			return a / b

		def return_string(self, s):
			return s

		def raise_my_error(self):
			raise MyError

		def raise_special_error(self):
			raise MySpecialError(1, 2, 3)


class MyError(Exception):
	pass


class MySpecialError(Exception):
	def __init__(self, arg1, arg2, arg3):
		pass
