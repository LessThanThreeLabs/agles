import eventlet
import os.path
import requests
import subprocess

from settings.deployment import DeploymentSettings
from settings.rabbit import RabbitSettings
from upgrade import upgrade_url


class Upgrader(object):
	def __init__(self, to_version, tar_fetcher):
		assert to_version
		self._to_version = to_version
		self._from_version = DeploymentSettings.version
		self._tar_fetcher = tar_fetcher

	def _get_upgrade_script(self):
		return ['bash', '-c',
			'&&'.join((
				"sudo rm -rf /tmp/koalityupgrade/%s" % self._to_version,
				"mkdir -p /tmp/koalityupgrade/%s" % self._to_version,
				"tar xf /tmp/%s.tar.gz -C /tmp/koalityupgrade/%s" % (self._to_version, self._to_version),
				"/tmp/koalityupgrade/%s/*/upgrade_script" % self._to_version
			))]

	def _get_revert_script(self):
		return ['bash', '-c', '/tmp/koalityupgrade/%s/*/revert_script' % self._to_version]

	def _set_upgrade_status(self, status, attempts=10):
		for attempt in xrange(attempts):
			try:
				DeploymentSettings.upgrade_status = status
			except:
				if attempt < attempts - 1:
					eventlet.sleep(3)
					RabbitSettings.reinitialize()
				else:
					raise

	def do_upgrade(self):
		if DeploymentSettings.upgrade_status == 'running':
			raise UpgradeInProgressException()

		self._set_upgrade_status('running', attempts=1)
		try:
			returncode = self._install_version(self._from_version, self._to_version)
			if returncode:
				self.revert_upgrade()
			else:
				self._set_upgrade_status('passed')
		except:
			self._set_upgrade_status('failed')

	def _install_version(self, from_version, to_version):
		license_key = DeploymentSettings.license_key
		server_id = DeploymentSettings.server_id
		self.download_upgrade_files(license_key, server_id, from_version, to_version, to_path='/tmp')
		return subprocess.call(self._get_upgrade_script())

	def revert_upgrade(self):
		returncode = subprocess.call(self._get_revert_script())
		if returncode:
			try:
				# log here
				self._set_upgrade_status('failed')
			finally:
				raise FatalUpgradeException()

		if self._to_version != 'latest':
			returncode = self._install_version(self._to_version, self._from_version)
			if returncode:
				try:
					# log here
					self._set_upgrade_status('failed')
				finally:
					raise FatalUpgradeException()
		self._set_upgrade_status('rolled back')

	def download_upgrade_files(self, license_key, server_id, from_version, to_version, to_path):
		download_path = os.path.join(to_path, "%s.tar.gz" % to_version)
		content = self._tar_fetcher.fetch_bytes(license_key, server_id, from_version, to_version)
		with open(download_path, "wb") as upgrade_tar:
			upgrade_tar.write(content)


class TarFetcher(object):
	def __init__(self, fetch_uri):
		self._fetch_uri = fetch_uri


class HttpTarFetcher(TarFetcher):
	def __init__(self, fetch_uri=upgrade_url):
		super(HttpTarFetcher, self).__init__(fetch_uri)

	def fetch_bytes(self, license_key, server_id, from_version, to_version):
		upgrade_data = {"licenseKey": license_key, "serverId": server_id, "currentVersion": from_version, "upgradeVersion": to_version}
		response = requests.get(self._fetch_uri, params=upgrade_data, verify=False)
		if not response.ok:
			raise UpgradeException("Failed to download upgrade tarball. upgrade_data: %s" % upgrade_data)
		return response.content


class UpgradeException(Exception):
	pass


class FatalUpgradeException(UpgradeException):
	pass


class UpgradeInProgressException(UpgradeException):
	def __init__(self):
		super(UpgradeInProgressException, self).__init__('An upgrade is already in progress')
