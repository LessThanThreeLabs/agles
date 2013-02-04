from settings.settings import Settings


class S3Settings(Settings):
	def __init__(self):
		super(S3Settings, self).__init__(
			media_bucket='com.lessthanthreelabs.media')

S3Settings.initialize()
