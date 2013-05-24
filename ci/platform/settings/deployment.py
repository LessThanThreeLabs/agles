from database_backed_settings import DatabaseBackedSettings
from shared.constants import VERSION


class DeploymentSettings(DatabaseBackedSettings):
	def __init__(self):
		super(DeploymentSettings, self).__init__(
			license_key=None,
			admin_api_key=None,
			active=False,
			server_id=None,
			version=VERSION,
			license_validation_failures=0,
			license_type=None,
			initialized=False
		)
