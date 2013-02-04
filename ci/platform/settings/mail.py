from settings import Settings


class MailSettings(Settings):
	def __init__(self):
		super(MailSettings, self).__init__(
			__file__,
			api_url='https://api.mailgun.net/v2/getkoality.com/messages',
			api_key='key-9e06ajco0xurqnioji-egwuwajg4jrn2',
			test_mode=True)

MailSettings.initialize()
