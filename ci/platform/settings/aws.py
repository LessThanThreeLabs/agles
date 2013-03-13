from settings import Settings


class AwsSettings(Settings):
	def __init__(self):
		super(AwsSettings, self).__init__(
			region="",
			aws_access_key_id="",
			aws_secret_access_key="",
			instance_type="m1.small",
			vm_image_name_prefix="precise64_box_")
		self.add_values(
			credentials=dict(
				aws_access_key_id=str(self.aws_access_key_id),
				aws_secret_access_key=str(self.aws_secret_access_key)),
			image_filter=lambda cls, image: image.name and image.name.startswith(AwsSettings.vm_image_name_prefix))


AwsSettings.initialize()
