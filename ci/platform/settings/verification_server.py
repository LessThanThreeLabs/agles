from database_backed_settings import DatabaseBackedSettings


class VerificationServerSettings(DatabaseBackedSettings):
	def __init__(self):
		super(VerificationServerSettings, self).__init__(
			max_virtual_machine_count=1,
			static_pool_size=1,
			local_box_name="precise64_verification")
