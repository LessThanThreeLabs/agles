import random

from functools import partial
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
		self.shared_work_queue = Queue(durable=False, auto_delete=False)(connection)
		self.shared_work_queue.queue_declare()
		self.producer = self.connection.Producer(serializer='msgpack')
		self.workers = {}

	def delegate_task(self, task):
		self._publish(self._as_task(task),
			routing_key=self.shared_work_queue.name,
			mandatory=True)

	def _as_task(self, task):
		return {"type": "task", "task": task}

	def _publish(self, message, **producer_kwargs):
		self.producer.publish(message,
			**producer_kwargs)

	def assign_workers(self, num_workers, queue, message=None):
		queue(self.connection).queue_declare()
		with self.connection.Consumer([queue], callbacks=[partial(self._new_worker, payload=message)], auto_declare=False):
			for worker in range(num_workers):
				self.connection.drain_nowait()
			print "Received %s out of %s workers" % (len(self.workers), num_workers)
			if len(self.workers) == 0:
				self.shared_work_queue.delete()
		return len(self.workers)

	def _new_worker(self, body, message, payload):
		self._add_worker(body["worker_id"], body["queue_name"], payload)
		message.ack()

	def _add_worker(self, name, queue, payload):
		self.workers[name] = {"queue_name": queue, "status": "working"}
		print "Allocated worker %s" % name
		with self.connection.Producer(serializer='msgpack') as producer:
			producer.publish({"type": "assign",
				"task_queue": self.shared_work_queue.name,
				"message": payload},
				routing_key=queue)


class InvalidResponseError(Exception):
	pass
