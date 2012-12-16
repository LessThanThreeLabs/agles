from verification.shared.build_core import OpenstackBuildCore, VagrantBuildCore
from virtual_machine.openstack import OpenstackVm
from virtual_machine.vagrant import Vagrant


class BuildVerifier(object):
	@classmethod
	def for_virtual_machine(cls, virtual_machine, uri_translator=None):
		if isinstance(virtual_machine, Vagrant):
			return VagrantBuildCore(virtual_machine, uri_translator)
		if isinstance(virtual_machine, OpenstackVm):
			return OpenstackBuildCore(virtual_machine, uri_translator)
		assert False
