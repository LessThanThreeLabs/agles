# model_server.py - Defines an abstraction on top of a database that allows for event firing

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""

from multiprocessing import Process

import pika

from bunnyrpc.client import Client
from repo.create_handler import RepoCreateHandler
from repo.read_handler import RepoReadHandler
from settings.rabbit import connection_parameters


class ModelServer(object):
	"""A higher level abstraction on top of the database that allows for event creation on database
	actions.

	All methods in this API return low level database objects such as row_results. This is only meant
	to be a thin abstraction that allows for proxying, not for higher level modification of the DB-API.
	"""

	rpc_handler_classes = [
		RepoCreateHandler,
		RepoReadHandler,
		]

	@classmethod
	def rpc_connect(cls, route):
		return Client("model-rpc", route)

	def __init__(self):
		# TODO(bbland): might want to not use blocking connection?
		self.rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.event_channel = self.rabbit_connection.channel()
		self.event_channel.exchange_declare(exchange='events', type='direct')

	def start(self):
		self.rpc_handler_processes = list()
		for rpc_handler_class in self.rpc_handler_classes:
			rpc_handler = rpc_handler_class()
			rpc_handler_process = Process(target=rpc_handler.start)
			self.rpc_handler_processes.append(rpc_handler_process)
			rpc_handler_process.daemon = True
			rpc_handler_process.start()

	def stop(self):
		map(lambda process: process.terminate() or process.join(), self.rpc_handler_processes)

	def subscribe(self, event):
		"""No-op

		This method is a placeholder. In the future, we may implement a callback
		based method where calling subscribe on the server will actually subscribe
		you to a channel.
		"""
		raise NotImplementedError(
			"Subscription should be done by binding to the zmq address")

	def publish(self, event, msg):
		"""Publishes a message to a specific event channel.

		:param event: The event channel to publish msg to.
		:param msg: The msg we are publishing to the channel.
		"""
		self.event_channel.basic_public(exchange='events',
            routing_key=event,
			body=msg,
			properties=pika.BasicProperties(
                delivery_mode=2,  # make message persistent
		    ))
