import random
import socket

from kombu.connection import Connection
from kombu.entity import Queue
from settings.rabbit import connection_info


class TaskWorker(object):
	def __init__(self, connection=None):
		random.seed()
		self.worker_id = str(random.random())[2:]
		self.connection = connection if connection else Connection(connection_info)

	def wait_for_assignment(self, worker_pool_queue):
		self.own_queue = Queue(auto_delete=True)(self.connection)
		self.own_queue.queue_declare()
		self.allocated = False
		self.results = []
		worker_pool_queue(self.connection).declare()
		with self.connection.Producer(serializer='msgpack', on_return=self._handle_return) as producer:
			producer.publish({"worker_id": self.worker_id, "queue_name": self.own_queue.name},
				exchange=worker_pool_queue.exchange,
				routing_key=worker_pool_queue.routing_key)
		with self.connection.Consumer([self.own_queue], callbacks=[self._assigned], auto_declare=False) as self.consumer:
			self.consumer.qos(prefetch_count=1)
			self.connection.drain_events()

	def _assigned(self, body, message):
		assert body["type"] == "assign"
		assert self.allocated == False
		self.allocated = True
		try:
			self.do_setup(body["message"])
			self._begin_listening(body["task_queue"], ack=message.delivery_tag)
		except Exception as e:
			print e
			self.results.append(e)
		finally:
			self._freed()

	def _begin_listening(self, shared_queue_name, ack):
		self.consumer.cancel()
		shared_queue = Queue(shared_queue_name)
		with self.connection.Consumer([shared_queue], callbacks=[self._handle_task], auto_declare=False) as self.consumer:
			self.consumer.channel.basic_ack(delivery_tag=ack)
			try:
				while True:
					self.connection.drain_events(timeout=1)
			except socket.timeout:
				pass

	def _freed(self):
		try:
			self.do_cleanup(self.results)
			self._stop_listening()
		except Exception as e:
			print e
		finally:
			self.allocated = False
			print "Worker %s freed" % self.worker_id

	def _stop_listening(self):
		self.consumer.cancel()

	def _handle_task(self, body, message):
		try:
			assert body["type"] == "task"
			self.results.append(self.do_task(body["task"]))
			message.ack()
		except Exception as e:
			print e
			message.requeue()

	def _handle_return(self, exception, exchange, routing_key, message):
		raise exception

	# To implement when extended

	def do_setup(self, message):
		pass

	def do_cleanup(self, results):
		pass

	def do_task(self, task):
		raise NotImplementedError()


class InvalidResponseError(Exception):
	pass


class InfiniteWorker(TaskWorker):
	def __init__(self, worker_pool_queue, connection=None):
		super(InfiniteWorker, self).__init__(connection)
		self.worker_pool_queue = worker_pool_queue

	def run(self):
		while True:
			self.wait_for_assignment(self.worker_pool_queue)


class InfinitePrinter(InfiniteWorker):
	def do_setup(self, message):
		print "Setup: %s" % message

	def do_task(self, task):
		print str(task)
