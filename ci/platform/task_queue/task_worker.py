import random

from kombu.connection import Connection
from kombu.entity import Queue
from settings.rabbit import connection_info


class TaskWorker(object):
	def __init__(self, worker_pool_queue, connection=None):
		random.seed()
		self.worker_id = str(random.random())[2:]
		self.connection = connection if connection else Connection(connection_info)
		self.worker_pool_queue = worker_pool_queue(self.connection)
		self.allocated = False

	def wait_for_invitation(self):
		with self.connection.Consumer([self.worker_pool_queue], callbacks=[self._invited]) as self.consumer:
			self.consumer.qos(prefetch_count=1)
			self.connection.drain_events()

	def handle_message(self, body, message):
		try:
			self._switch(body)
			self.consumer.channel.basic_ack(delivery_tag=message.delivery_tag)
		except Exception as e:
			raise e

	def _invited(self, body, message):
		assert body["type"] == "invite"
		assert self.allocated == False
		self.allocated = True
		self._begin_listening(body["shared_queue"], body["response_queue"], ack=message.delivery_tag)

	def do_task(self, body):
		raise NotImplementedError()

	def _freed(self, body):
		self._stop_listening()
		self.allocated = False
		print "Worker %s freed" % self.worker_id

	def _begin_listening(self, shared_queue_name, response_queue, ack):
		self.consumer.cancel()
		shared_queue = Queue(shared_queue_name, auto_delete=True)
		own_queue = Queue(auto_delete=True)(self.connection)
		own_queue.queue_declare()
		with self.connection.Consumer([shared_queue, own_queue], callbacks=[self.handle_message], auto_declare=False) as self.consumer:
			with self.connection.Producer(serializer='msgpack') as producer:
				producer.publish({"type": "new_worker", "from": self.worker_id, "queue_name": own_queue.name},
					routing_key=response_queue)
				self.consumer.channel.basic_ack(delivery_tag=ack)
			while self.allocated:
				self.connection.drain_events()

	def _stop_listening(self):
		self.consumer.cancel()

	def _switch(self, body):
		handlers = {"task": self.do_task,
			"free": self._freed}
		if handlers.get(body["type"]):
			handlers[body["type"]](body)
		else:
			raise InvalidResponseError(body["type"])


class InvalidResponseError(Exception):
	pass


class InfiniteWorker(TaskWorker):
	def __init__(self, worker_pool_queue):
		super(InfiniteWorker, self).__init__(worker_pool_queue)
		while True:
			self.wait_for_invitation()


class InfinitePrinter(InfiniteWorker):
	def do_task(self, body):
		print str(body["task"])
