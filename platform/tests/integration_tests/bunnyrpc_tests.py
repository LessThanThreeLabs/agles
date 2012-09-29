from multiprocessing import Process

from nose.tools import *

from bunnyrpc.client import Client
from bunnyrpc.server import Server
from util.test import BaseIntegrationTest


class BunnyRPCTest(BaseIntegrationTest):
	def setUp(self):
		super(BunnyRPCTest, self).setUp()
		self.p = Process(target=self._runserver,
			args=(self._TestRPCServer(), "exchange", ["queue0", "queue1"],))
		self.p.start()

	def tearDown(self):
		super(BunnyRPCTest, self).tearDown()
		self.p.terminate()

	def _runserver(self, base_instance, exchange, queue_names):
		server = Server(base_instance)
		server.bind(exchange, queue_names)
		server.run()

	def test_basic_clientserver_rpc(self):
		with Client("exchange", "queue0") as client:
			for i in xrange(1,10):
				server_count = client.incr()
				assert_equals(server_count, i)

	def test_exceptional_controlflow_rpc(self):
		with Client("exchange", "queue0", globals=globals()) as client:
			assert_raises(ZeroDivisionError, lambda: client.div(6, 0))
			assert_raises(MyError, lambda: client.raise_my_error())

	def _run_multiclients_in_tandem(self, client0, client1):
		try:
			for i in xrange(1,10):
				client = client0 if i % 2 == 0 else client1
				server_count = client.incr()
				assert_equals(server_count, i)
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
		pass

	class _TestRPCServer(object):
		def __init__(self):
			self.count = 0

		def incr(self):
			self.count += 1
			return self.count

		def div(self, a, b):
			return a/b

		def raise_my_error(self):
			raise MyError

class MyError(Exception):
	pass


