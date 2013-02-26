from settings import Settings


class TestS3Settings(Settings):
	def __init__(self):
		super(TestS3Settings, self).__init__(media_bucket='com.lessthanthreelabs.media')

TestS3Settings.initialize()
