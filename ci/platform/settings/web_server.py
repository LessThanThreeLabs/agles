from database_backed_settings import DatabaseBackedSettings


class WebServerSettings(DatabaseBackedSettings):
	def __init__(self):
		super(WebServerSettings, self).__init__(
			domain_name="koality.yourcompany.com"
		)
