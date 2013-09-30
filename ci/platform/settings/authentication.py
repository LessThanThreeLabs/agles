from database_backed_settings import DatabaseBackedSettings


class AuthenticationSettings(DatabaseBackedSettings):
	def __init__(self):
		super(AuthenticationSettings, self).__init__(
			allowed_connection_types=['default'],
			allowed_email_domains=['yourcompany.com'])
