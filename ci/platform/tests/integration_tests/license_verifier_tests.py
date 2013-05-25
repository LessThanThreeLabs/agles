from nose.tools import *
from license.verifier import LicenseVerifier, HttpLicenseKeyVerifier, LicenseKeyVerifier, LicensePermissionsHandler, MAX_FAILURES
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
		verifier = LicenseVerifier(HttpLicenseKeyVerifier(), LicensePermissionsHandler())
		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)
		for i in range(MAX_FAILURES + 1):
			assert_equals(i, DeploymentSettings.license_validation_failures)
			verifier.license_check_failed()

		assert_equals(False, DeploymentSettings.active)

	def test_reset_license_check_failures(self):
		verifier = LicenseVerifier(HttpLicenseKeyVerifier(), LicensePermissionsHandler())
		DeploymentSettings.initialize()
		for i in range(MAX_FAILURES + 1):
			assert_equals(i, DeploymentSettings.license_validation_failures)
			verifier.license_check_failed()

		assert_equals(False, DeploymentSettings.active)
		assert_true(DeploymentSettings.license_validation_failures > 0)

		verifier.reset_license_check_failures()
		assert_equals(0, DeploymentSettings.license_validation_failures)
		assert_equals(True, DeploymentSettings.active)

	def test_fail_to_deactivate(self):
		class FailingLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, license_key, server_id, user_count):
				return {'is_valid': False}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		verifier = LicenseVerifier(FailingLicenseKeyVerifier(), LicensePermissionsHandler())
		verifier.handle_once()

		assert_equal(1, DeploymentSettings.license_validation_failures)
		for i in range(MAX_FAILURES + 1):
			verifier.handle_once()

		assert_equals(False, DeploymentSettings.active)

	def test_verify_success(self):
		class PassingLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, license_key, server_id, user_count):
				return {'is_valid': True, 'license_type': 'bronze'}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		verifier = LicenseVerifier(PassingLicenseKeyVerifier(), LicensePermissionsHandler())
		for i in range(MAX_FAILURES + 1):
			verifier.handle_once()
			assert_equals(0, DeploymentSettings.license_validation_failures)
			assert_equals(True, DeploymentSettings.active)
