import logging
import random
import socket

from kombu.connection import Connection
from kombu.entity import Queue
from settings.rabbit import RabbitSettings


class TaskWorker(object):
	def __init__(self, connection=None):
		self.logger = logging.getLogger("TaskWorker")
		random.seed()
		self.worker_id = self.get_worker_id()
		self.connection = connection if connection else Connection(RabbitSettings.kombu_connection_info)

	def wait_for_assignment(self, worker_pool_queue):
		self.own_queue = Queue(auto_delete=True, durable=False)(self.connection)
		self.own_queue.queue_declare()
		self.logger.debug("Worker %s declared own queue %s" % (self.worker_id, self.own_queue.name))
		self.allocated = False
		self.results = []
		worker_pool_queue(self.connection).declare()
		self.logger.debug("Worker %s declared worker pool queue %s" % (self.worker_id, worker_pool_queue.name))
		with self.connection.Producer(serializer='msgpack', on_return=self._handle_return) as producer:
			producer.publish({"worker_id": self.worker_id, "queue_name": self.own_queue.name},
				exchange=worker_pool_queue.exchange,
				routing_key=worker_pool_queue.routing_key)
			self.logger.debug("Worker %s published own info" % self.worker_id)

		with self.connection.Consumer([self.own_queue], callbacks=[self._assigned], auto_declare=False) as self.consumer:
			self.consumer.qos(prefetch_count=1)
			self.waiting = True
			self.logger.debug("Worker %s waiting for assignment" % self.worker_id)
			while self.waiting:
				self.connection.drain_events()

	def _assigned(self, body, message):
		try:
			assert body["type"] == "assign"
			assert self.allocated == False
			self.allocated = True
			self.waiting = False
			self.logger.info("Worker %s assigned to task queue %s" % (self.worker_id, body["task_queue"]))
			self.consumer.cancel()
			message.ack()
			self.do_setup(body["message"])
			self._begin_listening(body["task_queue"])
		except Exception as e:
			self.logger.info("Assignment for worker %s failed" % self.worker_id, exc_info=True)
			self.results.append(e)
		finally:
			self._freed()

	def _begin_listening(self, shared_queue_name):
		shared_queue = Queue(shared_queue_name)
		try:
			with self.connection.Consumer([shared_queue], callbacks=[self._handle_task], auto_declare=False) as self.consumer:
				try:
					while True:
						self.connection.drain_events(timeout=1)
				except socket.timeout:
					pass
		except self.connection.transport.channel_errors:
			pass  # Looks like there's no work to be done anymore (queue nonexistent)

	def _freed(self):
		try:
			self.do_cleanup(self.results)
			self._stop_listening()
		except:
			self.logger.error("Worker %s failed to clean up" % self.worker_id, exc_info=True)
		finally:
			self.allocated = False
			self.logger.debug("Worker %s freed" % self.worker_id)

	def _stop_listening(self):
		self.consumer.cancel()

	def _handle_task(self, body, message):
		try:
			assert body["type"] == "task"
			self.results.append(self.do_task(body["task"]))
		except:
			self.logger.error("Worker %s failed to handle task %s" % (self.worker_id, body["task"]), exc_info=True)
			message.requeue()
		else:
			message.ack()

	def _handle_return(self, exception, exchange, routing_key, message):
		raise exception

	# To implement when extended

	def get_worker_id():
		pass

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
		try:
			while True:
				self.wait_for_assignment(self.worker_pool_queue)
		except BaseException as e:
			self.logger.exception(e)


class InfinitePrinter(InfiniteWorker):
	def do_setup(self, message):
		print "Setup: %s" % message

	def do_task(self, task):
		print str(task)
