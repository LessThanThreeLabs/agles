from bunnyrpc.server import Server
from events_broker import EventsBroker
from kombu.connection import Connection
from settings.rabbit import connection_info


class ModelServerRpcHandler(object):

	def __init__(self, rpc_noun, rpc_verb):
		assert isinstance(rpc_noun, str)
		assert isinstance(rpc_verb, str)

		self.rpc_noun = rpc_noun
		self.rpc_verb = rpc_verb
		self.rpc_queue_name = "rpc:%s.%s" % (rpc_noun, rpc_verb)

	def get_server(self, channel=None):
		rpc_handler = Server(self)
		rpc_handler.bind("model:rpc", [self.rpc_queue_name], channel=channel)
		return rpc_handler

	def start(self):
		self.get_server().run()

	def publish_event(self, _resource, _id, _event_type, **contents):
		"""A simple method for publishing a single event with the default
		rabbit connection info.
		Not recommended for use with multiple events.
		"""
		with Connection(connection_info) as connection:
			broker = EventsBroker(connection)
			broker.publish(_resource, _id, _event_type, **contents)
