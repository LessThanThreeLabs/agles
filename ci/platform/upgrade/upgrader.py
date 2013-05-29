import eventlet
import os.path
import requests

import bunnyrpc.exceptions

from provisioner.setup_tools import SetupScript, SetupCommand
from settings.deployment import DeploymentSettings


class Upgrader(object):
	def __init__(self, to_version, tar_fetcher):
		assert to_version
		self._to_version = to_version
		self._from_version = DeploymentSettings.version
		self._tar_fetcher = tar_fetcher

	def _get_upgrade_script(self):
		return SetupScript(
			SetupCommand(
				"sudo rm -rf /tmp/%s" % self._to_version,
				"tar xf /tmp/%s.tar.gz -C /tmp" % self._to_version,
				"/tmp/%s/upgrade_script" % self._to_version
			)
		)

	def _get_revert_script(self):
		return SetupScript(
			SetupCommand("/tmp/%s/revert_script" % self._to_version)
		)

	def do_upgrade(self):
		returncode = self._install_version(self._from_version, self._to_version)
		if returncode:
			self.revert_upgrade()
		else:
			for attempt in xrange(10):
				try:
					DeploymentSettings.version = self._to_version
				except bunnyrpc.exceptions.RPCRequestError:  # Model server might not be up again yet
					eventlet.sleep(3)
				else:
					break

	def _install_version(self, from_version, to_version):
		license_key = DeploymentSettings.license_key
		server_id = DeploymentSettings.server_id
		self.download_upgrade_files(license_key, server_id, from_version, to_version, to_path='/tmp')
		return self._get_upgrade_script().run().returncode

	def revert_upgrade(self):
		returncode = self._get_revert_script().run().returncode
		if returncode:
			# log here
			raise FatalUpgradeException()

		returncode = self._install_version(self._to_version, self._from_version)
		if returncode:
			# log here
			raise FatalUpgradeException()

	def download_upgrade_files(self, license_key, server_id, from_version, to_version, to_path):
		download_path = os.path.join(to_path, "%s.tar.gz" % to_version)
		content = self._tar_fetcher.fetch_bytes(license_key, server_id, from_version, to_version)
		with open(download_path, "wb") as upgrade_tar:
			upgrade_tar.write(content)


class TarFetcher(object):
	def __init__(self, fetch_uri):
		self._fetch_uri = fetch_uri


class HttpTarFetcher(TarFetcher):
	UPGRADE_URI = 'http://license.koalitycode.com:9001/upgrade'

	def __init__(self, fetch_uri=UPGRADE_URI):
		super(HttpTarFetcher, self).__init__(fetch_uri)

	def fetch_bytes(self, license_key, server_id, from_version, to_version):
		upgrade_data = {"licenseKey": license_key, "serverId": server_id, "currentVersion": from_version, "upgradeVersion": to_version}
		response = requests.post(self._fetch_uri, data=upgrade_data)
		if not response.ok:
			raise UpgradeException("Failed to download upgrade tarball. upgrade_data: %s" % upgrade_data)
		return response.content


class UpgradeException(Exception):
	pass


class FatalUpgradeException(UpgradeException):
	pass
