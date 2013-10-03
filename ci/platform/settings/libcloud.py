from database_backed_settings import DatabaseBackedSettings


class LibCloudSettings(DatabaseBackedSettings):
	def __init__(self):
		super(LibCloudSettings, self).__init__(
			cloud_provider='openstack',
			key='',
			secret='',
			extra_credentials={},
			instance_type='',
			largest_instance_type=None,
			vm_image_id=None,  # default to our 12.04 AMI
			security_group='koality_verification')
