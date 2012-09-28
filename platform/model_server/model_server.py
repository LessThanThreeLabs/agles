# model_server.py - Defines an abstraction on top of a database that allows for event firing

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""

import os
import pika

from sqlalchemy.sql import select

import database.schema

from bunnyrpc.server import Server
from bunnyrpc.client import Client
from database.engine import EngineFactory
from settings.rabbit import connection_parameters


class ModelServer(object):
	"""A higher level abstraction on top of the database that allows for event creation on database
	actions.

	All methods in this API return low level database objects such as row_results. This is only meant
	to be a thin abstraction that allows for proxying, not for higher level modification of the DB-API.
	"""

	rpc_nouns = ["repo", "users"]
	rpc_verbs = ["create", "read", "update", "delete"]

	@property
	def _db_conn(self):
		return EngineFactory.get_connection()

	@classmethod
	def start(cls):
		model_server = Server(ModelServer())
		queue_names = ["-".join(["rpc", rpc_noun, rpc_verb])
			for rpc_noun in cls.rpc_nouns
			for rpc_verb in cls.rpc_verbs]
		model_server.bind("model-rpc", queue_names)
		model_server.run()

	@classmethod
	def rpc_connect(cls, route):
		return Client("model-rpc", route)

	def __init__(self):
		# TODO(bbland): might want to not use blocking connection?
		self.rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.event_channel = self.rabbit_connection.channel()
		self.event_channel.exchange_declare(exchange='events', type='direct')

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

	def create_repo(self, repo_name, machine_id):
		# This is a stub that only does things that are needed for testing atm.
		# It needs to be completed
		repo = database.schema.repo
		repo_hash = os.urandom(16).encode('hex')
		ins = repo.insert().values(name=repo_name, hash=repo_hash, machine_id=machine_id)
		result = self._db_conn.execute(ins)
		return result.inserted_primary_key[0]

	def get_repo_address(self, repo_hash):
		repo = database.schema.repo
		uri_repo_map = database.schema.uri_repo_map
		query = repo.join(
            uri_repo_map).select().where(
			repo.c.hash==repo_hash)
		row = self._db_conn.execute(query).first()
		if row:
			return row[uri_repo_map.c.uri]
		else:
			return None

	def get_repo_name(self, repo_hash):
		repo = database.schema.repo
		query = repo.select().where(repo.c.hash==repo_hash)
		row = self._db_conn.execute(query).first()
		if row:
			return row[repo.c.name]
		else:
			return None

	def verify_public_key(self, key):
		ssh_pubkeys = database.schema.ssh_pubkeys
		query = ssh_pubkeys.select().where(ssh_pubkeys.c.ssh_key==key)
		row = self._db_conn.execute(query).first()
		if row:
			return row[ssh_pubkeys.c.user_id]
		else:
			return None

	def get_repo_attributes(self, requested_repo_uri):
		uri_repo_map = database.schema.uri_repo_map
		repo = database.schema.repo
		machine = database.schema.machine
		query = select([machine.c.uri, repo.c.hash, repo.c.name], from_obj=[
            uri_repo_map.select().where(uri_repo_map.c.uri==requested_repo_uri).alias().join(repo).join(machine)])
		row_result = self._db_conn.execute(query).first()
		return row_result[machine.c.uri], row_result[repo.c.hash], row_result[repo.c.name]
