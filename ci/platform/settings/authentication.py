from database_backed_settings import DatabaseBackedSettings


class AuthenticationSettings(DatabaseBackedSettings):
	def __init__(self):
		super(AuthenticationSettings, self).__init__(
			allowed_connection_types=[],
			allowed_email_domains=[])
