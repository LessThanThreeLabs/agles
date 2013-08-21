import database.schema
import eventlet

from sqlalchemy import and_

from bunnyrpc.server import Server
from database.engine import ConnectionFactory
from events_broker import EventsBroker
from kombu.connection import Connection
from settings.rabbit import RabbitSettings


class ModelServerRpcHandler(object):

	def __init__(self, rpc_noun, rpc_verb, channel):
		assert isinstance(rpc_noun, str)
		assert isinstance(rpc_verb, str)

		self.rpc_noun = rpc_noun
		self.rpc_verb = rpc_verb
		self.rpc_queue_name = "rpc:%s.%s" % (rpc_noun, rpc_verb)
		self.channel = channel or Connection(RabbitSettings.kombu_connection_info)
		self.producer_lock = eventlet.semaphore.Semaphore()

	def get_server(self):
		rpc_handler = Server(self)
		rpc_handler.bind("model:rpc", [self.rpc_queue_name], channel=self.channel, response_lock=self.producer_lock)
		return rpc_handler

	def publish_event(self, _resource, _id, _event_type, **_contents):
		"""A simple method for publishing a single event with the default
		rabbit connection info.
		Not recommended for use with multiple events.
		"""
		broker = EventsBroker(self.channel)
		broker.publish(self.producer_lock, _resource, _id, _event_type, **_contents)

	def publish_event_to_admins(self, _resource, _event_type, **_contents):
		user = database.schema.user

		query = user.select().where(
			and_(
				user.c.admin == True,
				user.c.deleted == 0
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)
		for row in rows:
			admin_id = row[user.c.id]
			self.publish_event(_resource, admin_id, _event_type, **_contents)

	def publish_event_to_all(self, _resource, _event_type, **_contents):
		user = database.schema.user

		query = user.select().where(user.c.deleted == 0)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)
		for row in rows:
			user_id = row[user.c.id]
			self.publish_event(_resource, user_id, _event_type, **_contents)
