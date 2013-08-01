from database_backed_settings import DatabaseBackedSettings
from shared.constants import VERSION


class DeploymentSettings(DatabaseBackedSettings):
	def __init__(self):
		super(DeploymentSettings, self).__init__(
			version=VERSION,
			active=False,
			server_id=None,
			admin_api_key=None,
			admin_api_active=None,
			initialized=False,
			upgrade_status=None,
			license_key=None,
			license_trial_expiration_time=None,
			license_unpaid_expiration_time=None,
			license_validation_failures=0,
			license_type=None,
		)
