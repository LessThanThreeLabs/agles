import operator
import random

import eventlet.queue
import msgpack

from kombu.connection import Connection
from kombu.entity import Queue
from settings.rabbit import connection_info


class TaskQueue(object):
	def __init__(self, connection=None):
		random.seed()
		self.queue_id = str(random.random())[2:]
		if not connection:
			connection = Connection(connection_info)
		self.connection = connection
		self.shared_work_queue = Queue(durable=False, auto_delete=True)(connection)
		self.shared_work_queue.queue_declare()
		self.producer = connection.Producer(serializer='msgpack', on_return=self._handle_return)
		self.response_queue = Queue(durable=False, auto_delete=True)(connection)
		self.response_queue.queue_declare()
		self.workers = {}

	def invite_workers(self, num_workers, exchange, routing_key):
		message = {"type": "invite",
			"shared_queue": self.shared_work_queue.name,
			"response_queue": self.response_queue.name}
		self.invite_queue = eventlet.queue.Queue()
		exchange(self.producer.channel).declare()

		with self.connection.Consumer([self.response_queue], callbacks=[self.handle_response], auto_declare=False):
			for worker in range(num_workers):
				self.producer.publish(message,
					exchange=exchange,
					routing_key=routing_key,
					immediate=True
				)
				self.producer.connection.drain_events()
				self.invite_queue.get()
		print "Received %s out of %s workers" % (len(self.workers), num_workers)
		return len(self.workers)

	def delegate_one(self, task):
		self._publish_task(task,
			routing_key=self.shared_work_queue.name,
			mandatory=True)

	def delegate_all(self, task):
		for worker in self.workers.itervalues():
			self._publish_task(task,
				routing_key=worker["queue_name"],
				mandatory=True)

	def _publish_task(self, task, **producer_kwargs):
		self.producer.publish({"type": "task", "task": task},
			**producer_kwargs)

	def close(self):
		for worker in self.workers.itervalues():
			self.producer.publish({"type": "free"},
				routing_key=worker["queue_name"],
				mandatory=True)

	def handle_response(self, body, message):
		try:
			self._switch(body)
		finally:
			message.ack()

	def _new_worker(self, body):
		self._add_worker(body["from"], body["queue_name"])

	def _add_worker(self, name, queue):
		if name and queue:
			self.workers[name] = {"queue_name": queue, "status": "working"}
			print "Allocated worker %s" % name
		self.invite_queue.put(name)

	def _results(self, body):
		print "Results %s from %s" % (body["results"], body["from"])

	def _worker_done(self, body):
		self.workers[body["from"]]["status"] = "done"
		if reduce(operator.and_, [worker["status"] == "done" for worker in self.workers], True):
			print "ALL WORKERS DONE"

	def _switch(self, body):
		handlers = {"new_worker": self._new_worker,
			"results": self._results,
			"done": self._worker_done}
		if handlers.get(body["type"]):
			handlers[body["type"]](body)
		else:
			raise InvalidResponseError(body["type"])

	def _handle_return(self, exception, exchange, routing_key, message):
		body = msgpack.unpackb(message.body)
		if body["type"] == "invite":
			self._add_worker(None, None)


class InvalidResponseError(Exception):
	pass
