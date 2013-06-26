import openstack

from settings.libcloud import LibCloudSettings
from util.log import Logged


class RackspaceClient(openstack.OpenstackClient):
	@classmethod
	def get_client(cls):
		credentials = LibCloudSettings.extra_credentials
		credentials['key'] = LibCloudSettings.key
		credentials['secret'] = LibCloudSettings.secret

		return cls.connect(credentials)

	@classmethod
	def validate_credentials(cls, credentials):
		try:
			cls.connect(credentials)
		except:
			return False
		else:
			return True

	@classmethod
	def connect(cls, credentials):
		assert 'region' in credentials

		region = credentials.pop('region')

		return super(RackspaceClient, cls).connect('rackspace_nova_%s' % region, credentials)


@Logged()
class RackspaceVm(openstack.OpenstackVm):
	CloudClient = RackspaceClient.get_client


class InstanceTypes(openstack.InstanceTypes):
	CloudClient = RackspaceClient.get_client
