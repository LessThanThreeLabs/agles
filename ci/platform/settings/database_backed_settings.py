import inspect
import os

import model_server


class DatabaseBackedSettings(object):
	class __metaclass__(type):
		def __getattr__(cls, attr):
			cls.initialize()
			if attr == '_resource' or attr.startswith('_'):
				attrname = attr[len('_default_'):] if attr.startswith('_default_') else attr
				raise AttributeError("'%s' object has no attribute '%s'" % (cls.__name__, attrname))
			setting = cls._retrieve_setting(attr)
			if setting:
				return setting
			return getattr(cls, '_default_' + attr)

		def __setattr__(cls, attr, value):
			if attr.startswith('_'):
				type.__setattr__(cls, attr, value)
				return
			cls._update_setting(attr, value)

	_is_initialized = False

	@classmethod
	def initialize(cls):
		if not cls._is_initialized:
			cls._is_initialized = True
			cls.reinitialize()

	@classmethod
	def reinitialize(cls):
		cls()

	def __init__(self, **kwargs):
		filename = os.path.basename(inspect.getfile(inspect.currentframe().f_back))
		setattr(type(self), '_resource', filename[:filename.rfind('.')])
		self._add_values(**kwargs)

	def _add_values(self, **kwargs):
		for name, default_value in kwargs.items():
			self._value(name, default_value)

	def _value(self, name, default_value):
		if inspect.isfunction(default_value):
			setattr(type(self), '_default_' + name, classmethod(default_value))
		else:
			setattr(type(self), '_default_' + name, default_value)

	@classmethod
	def _retrieve_setting(cls, attr):
		with model_server.rpc_connect("system_settings", "read") as model_server_rpc:
			return model_server_rpc.get_setting(cls._resource, attr)

	@classmethod
	def _update_setting(cls, attr, value):
		with model_server.rpc_connect("system_settings", "update") as model_server_rpc:
			model_server_rpc.update_setting(cls._resource, attr, value)
