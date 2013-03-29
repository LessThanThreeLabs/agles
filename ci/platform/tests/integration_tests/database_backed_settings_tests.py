from nose.tools import *

import model_server

from settings.database_backed_settings import DatabaseBackedSettings
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin


class DatabaseBackedSettingsTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	@classmethod
	def setup_class(cls):
		super(DatabaseBackedSettingsTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(DatabaseBackedSettingsTest, self).setUp()
		self._start_model_server()

	def tearDown(self):
		super(DatabaseBackedSettingsTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def test_default_settings(self):
		class SampleTestSettings(DatabaseBackedSettings):
			pass

		alpha = "abc"
		numeric = 123
		a_list = [1, "two", {3: "Three"}]
		a_dict = {"alpha": alpha, "numeric": numeric, "a_list": a_list}

		assert_raises(AttributeError, lambda: SampleTestSettings.alpha)

		SampleTestSettings(alpha=alpha, numeric=numeric, a_list=a_list, a_dict=a_dict)

		assert_equal(alpha, SampleTestSettings.alpha)
		assert_equal(numeric, SampleTestSettings.numeric)
		assert_equal(a_list, SampleTestSettings.a_list)
		assert_equal(a_dict, SampleTestSettings.a_dict)

		assert_raises(AttributeError, lambda: SampleTestSettings.not_a_setting)

	def test_override_settings(self):
		alpha = "abc"
		numeric = 123
		a_list = [1, "two", {3: "Three"}]
		a_dict = {"alpha": alpha, "numeric": numeric, "a_list": a_list}

		class SampleTestSettings(DatabaseBackedSettings):
			def __init__(self):
				super(SampleTestSettings, self).__init__(
					alpha=alpha,
					numeric=numeric,
					a_list=a_list,
					a_dict=a_dict
				)

		new_alpha = "zyx"
		self._change_setting("alpha", new_alpha)

		assert_equal(new_alpha, SampleTestSettings.alpha)
		assert_equal(numeric, SampleTestSettings.numeric)

		alphanumeric = "abc123XYZ"
		self._change_setting("alpha", alphanumeric)

		assert_equal(alphanumeric, SampleTestSettings.alpha)

	def test_add_new_settings(self):
		class SampleTestSettings(DatabaseBackedSettings):
			pass

		assert_raises(AttributeError, lambda: SampleTestSettings.a_list)

		a_list = [1, "two", {3: "Three"}]
		self._change_setting("a_list", a_list)

		assert_equal(a_list, SampleTestSettings.a_list)

	def test_set_attr(self):
		alpha = "abc"
		numeric = 123
		a_list = [1, "two", {3: "Three"}]
		a_dict = {"alpha": alpha, "numeric": numeric, "a_list": a_list}

		class SampleTestSettings(DatabaseBackedSettings):
			def __init__(self):
				super(SampleTestSettings, self).__init__(
					alpha=alpha,
					numeric=numeric,
					a_list=a_list,
					a_dict=a_dict
				)

		new_alpha = "zyx"
		SampleTestSettings.alpha = new_alpha

		assert_equal(new_alpha, SampleTestSettings.alpha)
		assert_equal(new_alpha, self._get_setting("alpha"))

		alphanumeric = "abc123XYZ"
		SampleTestSettings.alpha = alphanumeric

		assert_equal(alphanumeric, SampleTestSettings.alpha)
		assert_equal(alphanumeric, self._get_setting("alpha"))

	def test_resource(self):
		class SampleTestSettings(DatabaseBackedSettings):
			pass

		assert_equal('sample_test', SampleTestSettings._get_resource())

		class AsdfSettings(DatabaseBackedSettings):
			pass

		assert_equal('asdf', AsdfSettings._get_resource())

	def _change_setting(self, key, value):
		with model_server.rpc_connect("system_settings", "update") as model_server_rpc:
			model_server_rpc.update_setting("sample_test", key, value)

	def _get_setting(self, key):
		with model_server.rpc_connect("system_settings", "read") as model_server_rpc:
			return model_server_rpc.get_setting("sample_test", key)
