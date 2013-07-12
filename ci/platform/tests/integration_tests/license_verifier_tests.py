from nose.tools import *
from license.verifier import LicenseVerifier, HttpLicenseKeyVerifier, LicenseKeyVerifier, LicensePermissionsHandler, MAX_FAILURES
from settings.aws import AwsSettings
from settings.deployment import DeploymentSettings
from settings.store import StoreSettings
from settings.verification_server import VerificationServerSettings
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
				return {'isValid': False}

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
				return {
					'isValid': True,
					'licenseType': 'bronze',
					'trialExpiration': None,
					'unpaidExpiration': None
				}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		verifier = LicenseVerifier(PassingLicenseKeyVerifier(), LicensePermissionsHandler())
		for i in range(MAX_FAILURES + 1):
			verifier.handle_once()
			assert_equals(0, DeploymentSettings.license_validation_failures)
			assert_equals(True, DeploymentSettings.active)

	def test_restricted_license_permissions(self):
		largest_instance_type = 'm1.small'
		parallelization_cap = 42
		max_repository_count = 69
		admin_api_allowed = False

		class RestrictedPermissionsLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, license_key, server_id, user_count):
				return {
					'isValid': True,
					'licenseType': 'bronze',
					'trialExpiration': None,
					'unpaidExpiration': None,
					'permissions': {
						'largestInstanceType': largest_instance_type,
						'parallelizationCap': parallelization_cap,
						'maxRepositoryCount': max_repository_count,
						'adminApiAllowed': admin_api_allowed
					}
				}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		verifier = LicenseVerifier(RestrictedPermissionsLicenseKeyVerifier(), LicensePermissionsHandler())

		verifier.handle_once()

		assert_equals(0, DeploymentSettings.license_validation_failures)
		assert_equals(True, DeploymentSettings.active)

		assert_equals(largest_instance_type, AwsSettings.largest_instance_type)
		assert_equals(parallelization_cap, VerificationServerSettings.parallelization_cap)
		assert_equals(max_repository_count, StoreSettings.max_repository_count)
		assert_equals(admin_api_allowed, DeploymentSettings.admin_api_active)

	def test_malformed_license_permissions(self):
		old_parallelization_cap = VerificationServerSettings.parallelization_cap
		old_max_repository_count = StoreSettings.max_repository_count

		new_parallelization_cap = {'a': 'dictionary'}
		new_max_repository_count = 'a string'

		class MalformedPermissionsLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, license_key, server_id, user_count):
				return {
					'isValid': True,
					'licenseType': 'bronze',
					'trialExpiration': None,
					'unpaidExpiration': None,
					'permissions': {
						'parallelizationCap': new_parallelization_cap,
						'maxRepositoryCount': new_max_repository_count,
					}
				}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		verifier = LicenseVerifier(MalformedPermissionsLicenseKeyVerifier(), LicensePermissionsHandler())

		verifier.handle_once()

		assert_equals(0, DeploymentSettings.license_validation_failures)
		assert_equals(True, DeploymentSettings.active)

		assert_equals(old_parallelization_cap, VerificationServerSettings.parallelization_cap)
		assert_equals(old_max_repository_count, StoreSettings.max_repository_count)

	def test_unknown_license_permissions(self):
		class UnknownPermissionsLicenseKeyVerifier(LicenseKeyVerifier):
			def verify_valid(self, license_key, server_id, user_count):
				return {
					'isValid': True,
					'licenseType': 'bronze',
					'trialExpiration': None,
					'unpaidExpiration': None,
					'permissions': {
						'anUnknownPermission': 1337,
						'another_unknown_permission': None,
						'M0r3 uNKn0wn perMiss10n$?': ['an', 'arbitrary', 'list'],
					}
				}

		DeploymentSettings.active = True
		assert_equals(True, DeploymentSettings.active)

		verifier = LicenseVerifier(UnknownPermissionsLicenseKeyVerifier(), LicensePermissionsHandler())

		verifier.handle_once()

		assert_equals(0, DeploymentSettings.license_validation_failures)
		assert_equals(True, DeploymentSettings.active)
