import database.schema
import eventlet

from sqlalchemy import and_

from bunnyrpc.server import Server
from database.engine import ConnectionFactory
from events_broker import EventsBroker
from kombu.connection import Connection
from settings.rabbit import RabbitSettings


class ModelServerRpcHandler(object):

	def __init__(self, rpc_noun, rpc_verb):
		assert isinstance(rpc_noun, str)
		assert isinstance(rpc_verb, str)

		self.rpc_noun = rpc_noun
		self.rpc_verb = rpc_verb
		self.rpc_queue_name = "rpc:%s.%s" % (rpc_noun, rpc_verb)
		self.producer_lock = eventlet.semaphore.Semaphore()

	def get_server(self, channel=None):
		rpc_handler = Server(self)
		rpc_handler.bind("model:rpc", [self.rpc_queue_name], channel=channel, response_lock=self.producer_lock)
		return rpc_handler

	def start(self):
		self.get_server().run()

	def publish_event(self, _resource, _id, _event_type, **_contents):
		"""A simple method for publishing a single event with the default
		rabbit connection info.
		Not recommended for use with multiple events.
		"""
		with Connection(RabbitSettings.kombu_connection_info) as connection:
			broker = EventsBroker(connection)
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
