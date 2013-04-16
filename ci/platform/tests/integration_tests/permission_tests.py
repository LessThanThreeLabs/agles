from nose.tools import *

import model_server

from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from util.permissions import is_admin, AdminApi, InvalidPermissionsError


class PermissionTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	@classmethod
	def setup_class(cls):
		super(PermissionTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(PermissionTest, self).setUp()
		self._start_model_server()

	def tearDown(self):
		super(PermissionTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def _create_user(self, email, admin):
		with model_server.rpc_connect("users", "create") as rpc_conn:
			return rpc_conn.create_user(email, "first_name", "last_name", "hash", "salt", admin)

	def test_is_admin(self):
		non_admin_id = self._create_user("user1_email", False)
		admin_id = self._create_user("user2_email", True)

		assert_false(is_admin(non_admin_id))
		assert_true(is_admin(admin_id))

	def test_admin_api(self):
		non_admin_id = self._create_user("user1_email", False)
		admin_id = self._create_user("user2_email", True)
		non_user_id = 42

		assert_raises(InvalidPermissionsError, self._admin_api_method, non_admin_id)
		assert_raises(InvalidPermissionsError, self._admin_api_method, non_user_id)
		assert self._admin_api_method(admin_id)

	@AdminApi
	def _admin_api_method(self, user_id):
		return True
