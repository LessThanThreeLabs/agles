from database_backed_settings import DatabaseBackedSettings


class HipchatSettings(DatabaseBackedSettings):
	def __init__(self):
		super(HipchatSettings, self).__init__(
			token='',
			rooms=[])
