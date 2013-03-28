from database_backed_settings import DatabaseBackedSettings


class AwsSettings(DatabaseBackedSettings):
	def __init__(self):
		super(AwsSettings, self).__init__(
			region="",
			aws_access_key_id="",
			aws_secret_access_key="",
			instance_type="m1.small",
			vm_image_name_prefix="koality_verification_",
			security_groups=[],
			credentials=lambda cls: dict(
				aws_access_key_id=str(cls.aws_access_key_id),
				aws_secret_access_key=str(cls.aws_secret_access_key)))
