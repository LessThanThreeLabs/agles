from database_backed_settings import DatabaseBackedSettings


class StoreSettings(DatabaseBackedSettings):
	def __init__(self):
		super(StoreSettings, self).__init__(rpc_exchange_name='repostore:rpc')
