# aci.py - Defines an access control interface for the model server

"""Access control interface for the model server.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""

import zmq

import db.schema

from db.engine import EngineFactory
from settings.model_server import model_server_eventchan


class ModelServer(object):
	def __init__(self):
		context = zmq.Context.instance()
		self.event_channel = context.socket(zmq.PUB)
		self.event_channel.bind(model_server_eventchan)
		self.conn = EngineFactory.get_connecion()

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
		self.event_channel.send([event, msg])

	def verify_public_key(self, key):
		ssh_pubkeys = db.schema.ssh_pubkeys
		query = ssh_pubkeys.select().where(ssh_pubkeys.c.ssh_key==key)
		row = self.conn.execute(query).first()
		if row:
			return row[ssh_pubkeys.c.user_id]
		else:
			return None
