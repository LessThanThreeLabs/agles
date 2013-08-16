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
			vm_image_name_prefix='koality_verification',
			vm_image_name_suffix='precise',
			vm_image_name_version='0.3',
			security_group='koality_verification')
