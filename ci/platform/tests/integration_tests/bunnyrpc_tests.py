from multiprocessing import Event

from nose.tools import *

from bunnyrpc.client import Client, RPCRequestError
from bunnyrpc.server import Server
from util.test import BaseIntegrationTest
from util.test.mixins import RabbitMixin, TestProcess


class BunnyRPCTest(BaseIntegrationTest, RabbitMixin):
	def setUp(self):
		super(BunnyRPCTest, self).setUp()
		self._purge_queues()
		server_event = Event()
		self.server_process = TestProcess(target=self._runserver,
			args=[self._TestRPCServer(), "exchange", ["queue0", "queue1"], server_event])
		self.server_process.start()

		ttl_event = Event()
		self.ttl_process = TestProcess(target=self._runserver,
			args=[self._TestRPCServer(), "ttl_exchange", ["queue"], ttl_event],
					kwargs=dict(ttl=0))
		self.ttl_process.start()

		return_event = Event()
		self.returned_msg_process = TestProcess(target=self._runserver,
			args=[self._TestRPCServer(), "returned_exchange", [], return_event])
		self.returned_msg_process.start()

		server_event.wait()
		ttl_event.wait()
		return_event.wait()
		self.ttl_process.terminate()

	def tearDown(self):
		super(BunnyRPCTest, self).tearDown()
		self.server_process.terminate()
		self.returned_msg_process.terminate()
		self._purge_queues()

	def _runserver(self, base_instance, exchange,
					queue_names, event, ttl=30000):
		server = Server(base_instance)
		server.bind(exchange, queue_names, message_ttl=ttl, auto_delete=True)
		event.set()
		server.run()

	def test_basic_clientserver_rpc(self):
		with Client("exchange", "queue0") as client:
			for i in xrange(1, 10):
				server_count = client.incr()
				assert_equal(server_count, i)

	def test_exceptional_controlflow_rpc(self):
		with Client("exchange", "queue0", globals=globals()) as client:
			assert_raises(ZeroDivisionError, lambda: client.div(6, 0))
			assert_raises(MyError, lambda: client.raise_my_error())

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

	def test_deadlettering(self):
		with Client("ttl_exchange", "queue") as client:
			assert_raises(RPCRequestError, client.incr)

	def test_returned_message(self):
		with Client("returned_exchange", "queue") as client:
			assert_raises(RPCRequestError, client.incr)

	class _TestRPCServer(object):
		def __init__(self):
			self.count = 0

		def incr(self):
			self.count += 1
			return self.count

		def div(self, a, b):
			return a / b

		def raise_my_error(self):
			raise MyError


class MyError(Exception):
	pass
