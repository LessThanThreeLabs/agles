from database_backed_settings import DatabaseBackedSettings


class DockerSettings(DatabaseBackedSettings):
	def __init__(self):
		super(DockerSettings, self).__init__(
			container_username='root',
			container_repository='ubuntu',
			container_tag='precise')
