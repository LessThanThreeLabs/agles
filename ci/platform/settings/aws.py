from database_backed_settings import DatabaseBackedSettings


class AwsSettings(DatabaseBackedSettings):
	def __init__(self):
		super(AwsSettings, self).__init__(
			region='',
			aws_access_key_id='',
			aws_secret_access_key='',
			instance_type='m1.medium',
			largest_instance_type=None,
			vm_image_name_prefix='koality_verification_0.2',
			security_group='koality_verification',
			s3_bucket_name='')
