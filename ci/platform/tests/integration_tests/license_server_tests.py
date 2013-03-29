from nose.tools import *
from license.license_server import LicenseServer, MAX_FAILURES
from settings.deployment import DeploymentSettings
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin


class LicenseServerTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	def setUp(self):
		super(LicenseServerTest, self).setUp()
		self._purge_queues()
		self._start_model_server()

	def tearDown(self):
		super(LicenseServerTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	def test_license_check_failed(self):
		serve = LicenseServer()
		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)
		for i in range(MAX_FAILURES + 1):
			assert_equals(i, DeploymentSettings.license_validation_failures)
			serve.license_check_failed()

		assert_equals(False, DeploymentSettings.active)

	def test_reset_license_check_failures(self):
		serve = LicenseServer()
		DeploymentSettings.initialize()
		for i in range(MAX_FAILURES + 1):
			assert_equals(i, DeploymentSettings.license_validation_failures)
			serve.license_check_failed()

		assert_equals(False, DeploymentSettings.active)
		assert_true(DeploymentSettings.license_validation_failures > 0)

		serve.reset_license_check_failures()
		assert_equals(0, DeploymentSettings.license_validation_failures)
		assert_equals(True, DeploymentSettings.active)
