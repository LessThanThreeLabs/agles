from nose.tools import *

from model_server import ModelServer
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from util.permissions import is_admin


class PermissionTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	def setUp(self):
		super(PermissionTest, self).setUp()
		self._purge_queues()
		self._start_model_server()

	def tearDown(self):
		super(PermissionTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def _create_user(self, email, admin):
		with ModelServer.rpc_connect("users", "create") as rpc_conn:
			return rpc_conn.create_user(email, "first_name", "last_name", "hash", "salt", admin)

	def test_is_admin(self):
		non_admin_id = self._create_user("user1_email", False)
		admin_id = self._create_user("user2_email", True)

		assert_false(is_admin(non_admin_id))
		assert_true(is_admin(admin_id))
