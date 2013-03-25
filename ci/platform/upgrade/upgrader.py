import os.path
import requests

from database import schema
from database.engine import ConnectionFactory
from provisioner.setup_tools import SetupScript

UPGRADE_DOWNLOAD_URL = 'http://koalitycode.com/upgrade/do_upgrade'


class Upgrader(object):
	UPGRADE_SCRIPT = SetupScript(
		"sudo rm -rf /tmp/to_version",
		"tar xf /tmp/to_version.tar.gz -C /tmp",
		"cd /tmp/to_version/ci/platform",
		"sudo pip uninstall koality",
		"python setup.py clean",
		"python setup.py build",
		"sudo python setup.py install",

		"../web/back/compile.sh",
		"../web/front/compile.sh",

		"pg_dump koality > /tmp/db_backup",
		"alembic upgrade HEAD",
		"sudo supervisorctl restart all",
		"rm -rf /tmp/to_version"
	)

	def __init__(self, to_version):
		assert to_version is not None
		self._to_version = to_version
		self._from_version = int(self._get_meta(self, "version"))

	def do_upgrade(self):
		returncode = self._install_version(self._from_version, self._to_version)
		if returncode:
			self.revert_upgrade()

	def _install_version(self, from_version, to_version):
		license_key = self._get_meta("license_key")
		self.download_upgrade_files(license_key, from_version, to_version, to_path='/tmp')
		return self.UPGRADE_SCRIPT.run()

	def _get_meta(self, property_name):
		meta = schema.meta

		query = meta.select().where(meta.c.property_name == property_name)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return sqlconn.execute(query).first()

	def revert_upgrade(self):
		revert_script = SetupScript(
			"dropdb koality",
			"createdb koality",
			"psql koality < /tmp/db_backup"
		)

		returncode = revert_script.run()
		if returncode:
			# log here
			raise FatalUpgradeException()

		returncode = self._install_version(self._to_version, self._from_version)
		if returncode:
			# log here
			raise FatalUpgradeException()

	def download_upgrade_files(self, license_key, from_version, to_version, to_path):
		upgrade_data = {"key": license_key, "currentVersion": from_version, "upgradeVersion": to_version}
		res = requests.post(UPGRADE_DOWNLOAD_URL, data=upgrade_data)
		dowload_path = os.path.sep.join(to_path, "to_version.tar.gz")
		with open(dowload_path, "wb") as upgrade_tar:
			upgrade_tar.write(res.content)


class UpgradeException(Exception):
	pass


class FatalUpgradeException(UpgradeException):
	pass
