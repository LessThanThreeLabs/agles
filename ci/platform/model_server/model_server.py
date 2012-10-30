# model_server.py - Defines an abstraction on top of a database that allows for event firing

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""
from kombu import Connection

from bunnyrpc.client import Client
from builds.create_handler import BuildsCreateHandler
from builds.read_handler import BuildsReadHandler
from builds.update_handler import BuildsUpdateHandler
from build_outputs.update_handler import BuildOutputsUpdateHandler
from changes.create_handler import ChangesCreateHandler
from changes.read_handler import ChangesReadHandler
from changes.update_handler import ChangesUpdateHandler
from repos.create_handler import ReposCreateHandler
from repos.read_handler import ReposReadHandler
from settings.rabbit import connection_info
from users.create_handler import UsersCreateHandler
from users.read_handler import UserReadHandler


class ModelServer(object):
	"""A higher level abstraction on top of the database that allows for event creation on database
	actions.

	All methods in this API return low level database objects such as row_results. This is only meant
	to be a thin abstraction that allows for proxying, not for higher level modification of the DB-API.
	"""

	rpc_handler_classes = [
		BuildsCreateHandler,
		BuildsReadHandler,
		BuildsUpdateHandler,
		BuildOutputsUpdateHandler,
		ChangesCreateHandler,
		ChangesReadHandler,
		ChangesUpdateHandler,
		ReposCreateHandler,
		ReposReadHandler,
		UsersCreateHandler,
		UserReadHandler
	]

	@classmethod
	def rpc_connect(cls, route_noun, route_verb):
		route = "rpc:%s.%s" % (route_noun, route_verb)
		return Client("model:rpc", route)

	def __init__(self, channel=None):
		if channel:
			self.channel = channel
		else:
			connection = Connection(connection_info)
			self.channel = connection.channel()

	def start(self):
		map(lambda rpc_handler_class: rpc_handler_class().get_server(self.channel),
			self.rpc_handler_classes)
		while True:
			self.channel.connection.drain_events()
