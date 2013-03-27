from database_backed_settings import DatabaseBackedSettings


class AwsSettings(DatabaseBackedSettings):
	def __init__(self):
		super(AwsSettings, self).__init__(
			region="",
			aws_access_key_id="",
			aws_secret_access_key="",
			instance_type="m1.small",
			vm_image_name_prefix="koality_verification_",
			security_groups=[])
		self.add_values(
			credentials=dict(
				aws_access_key_id=str(self.aws_access_key_id),
				aws_secret_access_key=str(self.aws_secret_access_key)))
