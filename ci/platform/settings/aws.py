from database_backed_settings import DatabaseBackedSettings


class AwsSettings(DatabaseBackedSettings):
	def __init__(self):
		super(AwsSettings, self).__init__(
			region='',
			aws_access_key_id='',
			aws_secret_access_key='',
			instance_type='m1.medium',
			largest_instance_type=None,
			vm_image_id='default',  # default to our 12.04 AMI
			vm_username='lt3',
			security_group='koality_verification',
			root_drive_size=8,
			s3_bucket_name='',
			user_data='')
