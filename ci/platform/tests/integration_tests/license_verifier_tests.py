from nose.tools import *
from license.verifier import LicenseVerifier, HttpLicenseKeyVerifier, LicenseKeyVerifier, MAX_FAILURES
from settings.deployment import DeploymentSettings
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin


class LicenseVerifierTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	@classmethod
	def setup_class(cls):
		super(LicenseVerifierTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(LicenseVerifierTest, self).setUp()
		self._start_model_server(license_verifier=False)

	def tearDown(self):
		self._stop_model_server()
		self._purge_queues()
		super(LicenseVerifierTest, self).tearDown()

	def test_license_check_failed(self):
		serve = LicenseVerifier(HttpLicenseKeyVerifier())
		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)
		for i in range(MAX_FAILURES + 1):
			assert_equals(i, DeploymentSettings.license_validation_failures)
			serve.license_check_failed()

		assert_equals(False, DeploymentSettings.active)

	def test_reset_license_check_failures(self):
		serve = LicenseVerifier(HttpLicenseKeyVerifier())
		DeploymentSettings.initialize()
		for i in range(MAX_FAILURES + 1):
			assert_equals(i, DeploymentSettings.license_validation_failures)
			serve.license_check_failed()

		assert_equals(False, DeploymentSettings.active)
		assert_true(DeploymentSettings.license_validation_failures > 0)

		serve.reset_license_check_failures()
		assert_equals(0, DeploymentSettings.license_validation_failures)
		assert_equals(True, DeploymentSettings.active)

	def test_fail_to_deactivate(self):
		class FailingLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, key, server_id):
				return {'is_valid': False}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		serve = LicenseVerifier(FailingLicenseKeyVerifier())
		serve.handle_once()

		assert_equal(1, DeploymentSettings.license_validation_failures)
		for i in range(MAX_FAILURES + 1):
			serve.handle_once()

		assert_equals(False, DeploymentSettings.active)

	def test_verify_success(self):
		class PassingLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, key, server_id):
				return {'is_valid': True}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		serve = LicenseVerifier(PassingLicenseKeyVerifier())
		for i in range(MAX_FAILURES + 1):
			serve.handle_once()
			assert_equals(0, DeploymentSettings.license_validation_failures)
			assert_equals(True, DeploymentSettings.active)
