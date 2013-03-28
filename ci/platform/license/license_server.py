import time


import requests
import model_server

LICENSE_VERIFICATION_URL = 'https://koalitycode.com/license/check'
MAX_FAILURES = 12
HOUR = 7200


class LicenseServer(object):
	def __init__(self):
		super(LicenseServer, self).__init__()

	def run(self):
		while True:
			try:
				with model_server.rpc_connect("resource", "read") as client:
					info = client.get_license_info()
					valid = self._verify_key(info['key'], info['server_id'])
					if valid:
						client.reset_license_check_failures()
					else:
						failures = client.license_check_failed()
						if failures > MAX_FAILURES:
							client.deactivate_license()
			except:
				with model_server.rpc_connect("resource", "read") as client:
					failures = client.license_check_failed()
					if failures > MAX_FAILURES:
						client.deactivate_license()

			time.sleep(2*HOUR)

	def _verify_key(self, key, server_id):
		verification_data = {'key': key, 'server_id': server_id}
		response = requests.post(LICENSE_VERIFICATION_URL, data=verification_data)
		if response.status_code != requests.codes.ok:
			return False
		return response.text.lower() == 'true'
