import time

import requests

from settings.deployment import DeploymentSettings


LICENSE_VERIFICATION_URL = 'https://koalitycode.com/license/check'
MAX_FAILURES = 12
HOUR = 3600


class LicenseServer(object):
	def __init__(self):
		super(LicenseServer, self).__init__()

	def run(self):
		while True:
			try:
				key = DeploymentSettings.license
				server_id = DeploymentSettings.server_id
				valid = self.verify_key(key, server_id)

				if valid:
					self.reset_license_check_failures()
				else:
					self.license_check_failed()
			except:
				self.license_check_failed()

			time.sleep(2*HOUR)

	def verify_key(self, key, server_id):
		verification_data = {'key': key, 'server_id': server_id}
		response = requests.post(LICENSE_VERIFICATION_URL, data=verification_data)
		if response.status_code != requests.codes.ok:
			return False
		return response.text.lower() == 'true'

	def reset_license_check_failures(self):
		DeploymentSettings.license_validation_failures = 0
		DeploymentSettings.active = True

	def license_check_failed(self):
		failures = DeploymentSettings.license_validation_failures + 1
		DeploymentSettings.license_validation_failures = failures

		if failures > MAX_FAILURES:
			DeploymentSettings.active = False
