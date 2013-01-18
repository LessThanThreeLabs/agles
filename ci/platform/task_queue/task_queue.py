import logging

from kombu.connection import Connection
from kombu.entity import Queue
from settings.rabbit import connection_info


class TaskQueue(object):
	def __init__(self, connection=None):
		self.logger = logging.getLogger("TaskQueue")
		if not connection:
			connection = Connection(connection_info)
		self.connection = connection
		self.shared_work_queue = Queue(durable=False, auto_delete=True)(connection)
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

	def get_workers(self, num_workers, queue):
		queue(self.connection).queue_declare()
		with self.connection.channel() as channel:
			with channel.Consumer([queue], callbacks=[self._new_worker], auto_declare=False):
				self.worker_attempt = 0
				while self.worker_attempt < num_workers:
					self.connection.drain_nowait()
					self.worker_attempt = self.worker_attempt + 1
				self.logger.info("Received %s out of %s workers" % (len(self.workers), num_workers))
				if len(self.workers) == 0:
					self.shared_work_queue.delete()
		return self.workers

	def _new_worker(self, body, message):
		try:
			queue = Queue(body["queue_name"])(self.connection)
			queue_name, message_count, consumer_count = queue.queue_declare(passive=True)
		except self.connection.transport.channel_errors:
			self.logger.warn("Worker queue %s not found", body["queue_name"])
			self._fail_new_worker(body["worker_id"], body["queue_name"])  # Queue doesn't exist, worker is dead
		else:
			if not consumer_count:
				self.loger.warn("Worker queue %s has no consumers, should have %s" % (body["queue_name"], body["worker_id"]))
				try:
					queue.delete()
				except self.connection.transport.channel_errors:
					self.logger.error("Failed to delete queue %s with no consumers" % queue.name, exc_info=True)
				finally:
					self._fail_new_worker(body["worker_id", body["queue_name"]])
			self._add_worker(body["worker_id"], body["queue_name"])
		message.ack()

	def _fail_new_worker(self, name, queue):
		self.worker_attempt = self.worker_attempt - 1
		self.logger.info("Worker %s on queue %s rejected" % (name, queue))

	def _add_worker(self, name, queue):
		self.workers[name] = {"queue_name": queue, "status": "working"}
		self.logger.info("Allocated worker %s with queue %s" % (name, queue))

	def assign_workers(self, workers, message):
		for worker in self.workers.itervalues():
			self.assign_worker(worker, message)

	def assign_worker(self, worker, message):
		with self.connection.Producer(serializer='msgpack') as producer:
			producer.publish({"type": "assign",
				"task_queue": self.shared_work_queue.name,
				"message": message},
				routing_key=worker["queue_name"])


class InvalidResponseError(Exception):
	pass
