from nose.tools import *

import model_server

from settings.database_backed_settings import DatabaseBackedSettings
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin


class DatabaseBackedSettingsTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	def setUp(self):
		super(DatabaseBackedSettingsTest, self).setUp()
		self._purge_queues()
		self._start_model_server()

	def tearDown(self):
		super(DatabaseBackedSettingsTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def test_default_settings(self):
		class TestSettings(DatabaseBackedSettings):
			pass

		alpha = "abc"
		numeric = 123
		a_list = [1, "two", {3: "Three"}]
		a_dict = {"alpha": alpha, "numeric": numeric, "a_list": a_list}

		assert_raises(AttributeError, lambda: TestSettings.alpha)

		TestSettings(alpha=alpha, numeric=numeric, a_list=a_list, a_dict=a_dict)

		assert_equal(alpha, TestSettings.alpha)
		assert_equal(numeric, TestSettings.numeric)
		assert_equal(a_list, TestSettings.a_list)
		assert_equal(a_dict, TestSettings.a_dict)

		assert_raises(AttributeError, lambda: TestSettings.not_a_setting)

	def test_override_settings(self):
		class TestSettings(DatabaseBackedSettings):
			pass

		alpha = "abc"
		numeric = 123
		a_list = [1, "two", {3: "Three"}]
		a_dict = {"alpha": alpha, "numeric": numeric, "a_list": a_list}

		TestSettings(alpha=alpha, numeric=numeric, a_list=a_list, a_dict=a_dict)

		new_alpha = "zyx"
		self._change_setting("alpha", new_alpha)

		assert_equal(new_alpha, TestSettings.alpha)
		assert_equal(numeric, TestSettings.numeric)

		alphanumeric = "abc123XYZ"
		self._change_setting("alpha", alphanumeric)

		assert_equal(alphanumeric, TestSettings.alpha)

	def test_add_new_settings(self):
		class TestSettings(DatabaseBackedSettings):
			pass

		TestSettings()

		assert_raises(AttributeError, lambda: TestSettings.a_list)

		a_list = [1, "two", {3: "Three"}]
		self._change_setting("a_list", a_list)

		assert_equal(a_list, TestSettings.a_list)

	def test_set_attr(self):
		class TestSettings(DatabaseBackedSettings):
			pass

		alpha = "abc"
		numeric = 123
		a_list = [1, "two", {3: "Three"}]
		a_dict = {"alpha": alpha, "numeric": numeric, "a_list": a_list}

		TestSettings(alpha=alpha, numeric=numeric, a_list=a_list, a_dict=a_dict)

		new_alpha = "zyx"
		TestSettings.alpha = new_alpha

		assert_equal(new_alpha, TestSettings.alpha)
		assert_equal(new_alpha, self._get_setting("alpha"))

		alphanumeric = "abc123XYZ"
		TestSettings.alpha = alphanumeric

		assert_equal(alphanumeric, TestSettings.alpha)
		assert_equal(alphanumeric, self._get_setting("alpha"))

	def _change_setting(self, key, value):
		with model_server.rpc_connect("system_settings", "update") as model_server_rpc:
			model_server_rpc.update_setting("database_backed_settings_test", key, value)

	def _get_setting(self, key):
		with model_server.rpc_connect("system_settings", "read") as model_server_rpc:
			return model_server_rpc.get_setting("database_backed_settings_test", key)
