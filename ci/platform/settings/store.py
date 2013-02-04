from settings import Settings


class StoreSettings(Settings):
	def __init__(self):
		super(StoreSettings, self).__init__(
			rpc_exchange_name='repostore:rpc')

StoreSettings.initialize()
