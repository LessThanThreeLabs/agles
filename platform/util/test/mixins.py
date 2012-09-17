""" mixins.py - contains test mixins

This module contains all mixins meant to be used for unit testing.

Mixins are NOT meant to be instantiated and should never be instantiated.
Instantiating a mixin violates the mixin paradigm and will have unintended side
consequences/side effects.
"""
import gevent

import settings.model_server
from model_server import ModelServer


class BaseTestMixin(object):
	"""A base class for testing mixins."""
	pass

class ModelServerTestMixin(BaseTestMixin):
	"""Mixin for integration tests that require a running model server"""

	def _start_model_server(self):
		self.model_server = gevent.spawn(
			ModelServer.start, settings.model_server.model_server_rpc_address)

	def _stop_model_server(self):
		self.model_server.kill()