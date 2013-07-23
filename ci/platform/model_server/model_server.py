# model_server.py - Defines an abstraction on top of a database that allows for event firing

"""Interface for the model server and database calls.

This class contains the api that is exposed to clients
and is the only point of interaction between clients and the model server.
"""
import eventlet
import sys

from kombu.connection import Connection

from builds.create_handler import BuildsCreateHandler
from builds.read_handler import BuildsReadHandler
from builds.update_handler import BuildsUpdateHandler
from build_consoles.read_handler import BuildConsolesReadHandler
from build_consoles.update_handler import BuildConsolesUpdateHandler
from changes.create_handler import ChangesCreateHandler
from changes.read_handler import ChangesReadHandler
from changes.update_handler import ChangesUpdateHandler
from license import verifier
from repos.create_handler import ReposCreateHandler
from repos.read_handler import ReposReadHandler
from repos.update_handler import ReposUpdateHandler
from repos.delete_handler import ReposDeleteHandler
from settings.rabbit import RabbitSettings
from system_settings.read_handler import SystemSettingsReadHandler
from system_settings.update_handler import SystemSettingsUpdateHandler
from users.create_handler import UsersCreateHandler
from users.read_handler import UsersReadHandler
from users.update_handler import UsersUpdateHandler
from users.delete_handler import UsersDeleteHandler
from util.log import Logged


@Logged()
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
		BuildConsolesReadHandler,
		BuildConsolesUpdateHandler,
		ChangesCreateHandler,
		ChangesReadHandler,
		ChangesUpdateHandler,
		ReposCreateHandler,
		ReposReadHandler,
		ReposUpdateHandler,
		ReposDeleteHandler,
		SystemSettingsReadHandler,
		SystemSettingsUpdateHandler,
		UsersCreateHandler,
		UsersReadHandler,
		UsersUpdateHandler,
		UsersDeleteHandler
	]

	def __init__(self, connection=None):
		if connection:
			self.connection = connection
		else:
			self.connection = Connection(RabbitSettings.kombu_connection_info)

	def start(self, license_verifier=True):
		greenlets_started_event = eventlet.event.Event()

		main_greenlet = eventlet.spawn(self._start, license_verifier, greenlets_started_event)
		greenlets_started_event.wait()
		return main_greenlet

	def _start(self, license_verifier, started_event):
		model_server_start_event = eventlet.event.Event()
		server_greenlets = []

		def send_if_unset(event, *args):
			if not event.ready():
				event.send_exception(*args)

		def ioloop_link(greenlet):
			self.connection.close()
			try:
				greenlet.wait()
			except:
				send_if_unset(model_server_start_event, *sys.exc_info())
			send_if_unset(model_server_start_event, ModelServerError)

		map(lambda rpc_handler_class: rpc_handler_class().get_server(self.connection.channel()),
			self.rpc_handler_classes)
		ioloop_greenlet = eventlet.spawn(self._ioloop)
		ioloop_greenlet.link(ioloop_link)
		server_greenlets.append(ioloop_greenlet)

		if license_verifier:
			key_verifier = verifier.HttpLicenseKeyVerifier()
			permissions_handler = verifier.LicensePermissionsHandler()
			lv = verifier.LicenseVerifier(key_verifier, permissions_handler)
			license_verifier_greenlet = eventlet.spawn(lv.poll)

			def license_verifier_link(greenlet):
				try:
					greenlet.wait()
				except:
					send_if_unset(model_server_start_event, *sys.exc_info())
				send_if_unset(model_server_start_event, ModelServerError)
			license_verifier_greenlet.link(license_verifier_link)
			server_greenlets.append(license_verifier_greenlet)
		try:
			started_event.send()
			model_server_start_event.wait()
		finally:
			for g in server_greenlets:
				g.kill()

	def _ioloop(self):
		try:
			while True:
				self.connection.drain_events()
		except:
			exc_info = sys.exc_info()
			self.logger.critical("Model server IOloop exited", exc_info=exc_info)
			raise exc_info


class ModelServerError(Exception):
	pass
