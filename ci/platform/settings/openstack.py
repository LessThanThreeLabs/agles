from database_backed_settings import DatabaseBackedSettings


class OpenstackSettings(DatabaseBackedSettings):
	def __init__(self):
		super(OpenstackSettings, self).__init__(
			version="2",
			username="",
			api_key="",
			project_name="",
			auth_url="",
			auth_system="",
			region_name="",
			vm_image_name_prefix="koality_verification_",
			credentials=lambda cls: ([str(cls.version), str(cls.username), str(cls.api_key), str(cls.project_name)], dict(
				auth_url=str(cls.auth_url), auth_system=str(cls.auth_system),
				region_name=str(cls.region_name) if cls.region_name else None)),
			image_filter=lambda cls, image: image.name.startswith(cls.vm_image_name_prefix))
