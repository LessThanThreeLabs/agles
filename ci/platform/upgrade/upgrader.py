import os.path
import requests

from provisioner.setup_tools import SetupScript, SetupCommand
from settings.deployment import DeploymentSettings


class Upgrader(object):
	def __init__(self, to_version, upgrade_download_url):
		assert to_version
		self._to_version = to_version
		self._from_version = DeploymentSettings.version
		self._upgrade_download_url = upgrade_download_url

	def _get_upgrade_script(self):
		return SetupScript(
			SetupCommand(
				"sudo rm -rf /tmp/%s" % self._to_version,
				"tar xf /tmp/%s.tar.gz -C /tmp" % self._to_version,
				"cat /tmp/%s/upgrade_script" % self._to_version
			)
		)

	def _get_revert_script(self):
		return SetupScript(
			SetupCommand("cat /tmp/%s/revert_script" % self._to_version)
		)

	def do_upgrade(self):
		returncode = self._install_version(self._from_version, self._to_version)
		if returncode:
			self.revert_upgrade()
		else:
			DeploymentSettings.version = self._to_version

	def _install_version(self, from_version, to_version):
		license_key = DeploymentSettings.license
		self.download_upgrade_files(license_key, from_version, to_version, to_path='/tmp')
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

	def download_upgrade_files(self, license_key, from_version, to_version, to_path):
		upgrade_data = {"key": license_key, "currentVersion": from_version, "upgradeVersion": to_version}
		response = requests.post(self._upgrade_download_url, data=upgrade_data)
		if response.status_code != requests.codes.ok:
			raise UpgradeException("Failed to download upgrade tarball. upgrade_data: %s" % upgrade_data)

		dowload_path = os.path.join(to_path, "%s.tar.gz" % to_version)
		with open(dowload_path, "wb") as upgrade_tar:
			upgrade_tar.write(response.content)


class UpgradeException(Exception):
	pass


class FatalUpgradeException(UpgradeException):
	pass
