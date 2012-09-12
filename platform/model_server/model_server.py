# aci.py - Defines an access control interface for the model server

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""

import pika

import database.schema

from settings.rabbit import connection_parameters
from database.engine import EngineFactory


class ModelServer(object):
	def __init__(self):
		# TODO(bbland): might want to not use blocking connection?
		self.rabbit_connection = pika.BlockingConnection(connection_parameters)

		self.event_channel = self.rabbit_connection.channel()
		self.event_channel.exchange_declare(exchange='events',
				type='direct')

		# TODO(bbland): uncomment this
		self.conn = EngineFactory.get_connection()

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

	def get_repo_address(self, repo_hash):
		repo = database.schema.repo
		uri_repository_map = database.schema.uri_repository_map
		query = repo.join(
				uri_repository_map).select().where(
				repo.c.hash==repo_hash)
		row = self.conn.execute(query).first()
		if row:
			return row[uri_repository_map.c.uri]
		else:
			return None

	def verify_public_key(self, key):
		ssh_pubkeys = database.schema.ssh_pubkeys
		query = ssh_pubkeys.select().where(ssh_pubkeys.c.ssh_key==key)
		row = self.conn.execute(query).first()
		if row:
			return row[ssh_pubkeys.c.user_id]
		else:
			return None
