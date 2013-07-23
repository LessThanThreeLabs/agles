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

		connection_parameters = {
			'ex_force_auth_url': 'https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/',
			'ex_force_auth_version': '2.0_keypair',
			'ex_force_service_name': 'Compute',
			'ex_force_service_region': 'az-1.region-a.geo-1',
		}
		connection_parameters.update(credentials)

		return super(HpCloudClient, cls).connect('openstack', connection_parameters)


@Logged()
class HpCloudVm(openstack.OpenstackVm):
	CloudClient = HpCloudClient.get_client

	def ssh_call(self, command, output_handler=None, timeout=None):
		# For some reason, hpcloud returns [<private ip>, <public ip>] as the private ips, and the private ips begin with 10.*
		private_ip = filter(lambda ip_address: ip_address.startswith('10.'), self.instance.private_ips)[0]
		login = "%s@%s" % (self.vm_username, private_ip)
		return self.call(["ssh", "-oLogLevel=error", "-oStrictHostKeyChecking=no", login, command], timeout=timeout, output_handler=output_handler)

	@classmethod
	def _get_instance_size(cls, instance_type, matching_attribute='name'):
		return filter(lambda size: getattr(size, matching_attribute) == instance_type, cls.CloudClient().list_sizes())[0]


class InstanceTypes(openstack.InstanceTypes):
	CloudClient = HpCloudClient.get_client

	@classmethod
	def get_allowed_instance_types(cls):
		largest_instance_type = LibCloudSettings.largest_instance_type
		ordered_types = map(lambda size: size.name, sorted(cls.CloudClient().list_sizes(), key=lambda size: size.ram))
		if largest_instance_type in ordered_types:
			return ordered_types[:ordered_types.index(largest_instance_type) + 1]
		else:
			return ordered_types
