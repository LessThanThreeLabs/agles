from database_backed_settings import DatabaseBackedSettings


class GithubEnterpriseSettings(DatabaseBackedSettings):
	def __init__(self):
		super(GithubEnterpriseSettings, self).__init__(
			github_url='github.yourcompany.com',
			client_id='',
			client_secret='')
