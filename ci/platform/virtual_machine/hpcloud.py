import openstack

from settings.libcloud import LibCloudSettings
from util.log import Logged


class HpCloudClient(openstack.OpenstackClient):
	@classmethod
	def get_client(cls):
		credentials = LibCloudSettings.extra_credentials
		credentials['key'] = LibCloudSettings.key
		credentials['secret'] = LibCloudSettings.secret

		return cls.connect(credentials)

	@classmethod
	def validate_credentials(cls, credentials):
		try:
			cls.connect(credentials).list_nodes()
		except:
			return False
		else:
			return True

	@classmethod
	def connect(cls, credentials):
		assert 'ex_tenant_name' in credentials
		region = credentials.get('ex_force_service_region', 'az-1.region-a.geo-1')

		connection_parameters = {
			'ex_force_auth_url': 'https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/',
			'ex_force_auth_version': '2.0_keypair',
			'ex_force_service_name': 'Compute',
			'ex_force_service_region': region,
		}
		connection_parameters.update(credentials)

		return super(HpCloudClient, cls).connect('openstack', connection_parameters)


@Logged()
class HpCloudVm(openstack.OpenstackVm):
	CloudClient = HpCloudClient.get_client

	def ssh_args(self):
		# For some reason, hpcloud returns [<private ip>, <public ip>] as the private ips, and the private ips begin with 10.*
		private_ip = filter(lambda ip_address: ip_address.startswith('10.'), self.instance.private_ips)[0]
		options = {
			'LogLevel': 'error',
			'StrictHostKeyChecking': 'no',
			'UserKnownHostsFile': '/dev/null',
			'ServerAliveInterval': '20'
		}
		return self.SshArgs(self.vm_username, private_ip, options=options)

	@classmethod
	def _get_instance_size(cls, instance_type, matching_attribute='name'):
		return filter(lambda size: getattr(size, matching_attribute) == instance_type, cls.CloudClient().list_sizes())[0]


class SecurityGroups(openstack.SecurityGroups):
	CloudClient = HpCloudClient.get_client


class InstanceTypes(openstack.InstanceTypes):
	CloudClient = HpCloudClient.get_client

	@classmethod
	def get_allowed_instance_types(cls):
		largest_instance_type = LibCloudSettings.largest_instance_type
		try:
			ordered_types = map(lambda size: size.name, sorted(cls.CloudClient().list_sizes(), key=lambda size: size.ram))
		except:
			return []
		if largest_instance_type in ordered_types:
			return ordered_types[:ordered_types.index(largest_instance_type) + 1]
		else:
			return ordered_types


class Regions(object):
	CloudClient = HpCloudClient.get_client

	@classmethod
	def get_allowed_regions(cls):
		return ['az-1.region-a.geo-1', 'az-2.region-a.geo-1', 'az-3.region-a.geo-1']
