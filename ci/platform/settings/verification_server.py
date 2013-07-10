from database_backed_settings import DatabaseBackedSettings


class VerificationServerSettings(DatabaseBackedSettings):
	def __init__(self):
		super(VerificationServerSettings, self).__init__(
			cloud_provider=None,
			max_virtual_machine_count=1,
			static_pool_size=1,
			teardown_after_build=True,
			parallelization_cap=32)
