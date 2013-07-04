from database_backed_settings import DatabaseBackedSettings


class LibCloudSettings(DatabaseBackedSettings):
	def __init__(self):
		super(LibCloudSettings, self).__init__(
			cloud_provider='openstack',
			key='',
			secret='',
			extra_credentials={},
			instance_type='',
			vm_image_name_prefix='koality_verification_0.1',
			largest_instance_type=None)
