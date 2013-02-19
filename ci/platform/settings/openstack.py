from settings import Settings


class OpenstackSettings(Settings):
	def __init__(self):
		super(OpenstackSettings, self).__init__(
			version="2",
			username="lessthanthree",
			api_key="8eb41c1eaab4e10b3e7603d7630b26c3",
			project_name="lessthanthree",
			auth_url="https://identity.api.rackspacecloud.com/v2.0/",
			auth_system="rackspace",
			region_name="DFW",
			vm_image_name_prefix="precise64_box_")
		self.add_values(
			credentials=([str(self.version), str(self.username), str(self.api_key), str(self.project_name)], dict(
				auth_url=str(self.auth_url), auth_system=str(self.auth_system),
				region_name=str(self.region_name) if self.region_name else None)),
			image_filter=lambda cls, image: image.name.startswith(OpenstackSettings.vm_image_name_prefix))

OpenstackSettings.initialize()
