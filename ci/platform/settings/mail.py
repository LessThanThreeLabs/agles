from database_backed_settings import DatabaseBackedSettings


class MailSettings(DatabaseBackedSettings):
	def __init__(self):
		super(MailSettings, self).__init__(
			api_url='https://api.mailgun.net/v2/koalitycode.com/messages',
			api_key='key-9e06ajco0xurqnioji-egwuwajg4jrn2',
			test_mode=True)
