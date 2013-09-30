import os
import pipes

from verification.build_core import VirtualMachineBuildCore
from virtual_machine.virtual_machine import VirtualMachine
from util.uri_translator import RepositoryUriTranslator


class FakeBuildCore(VirtualMachineBuildCore):
	def __init__(self, vm_id):
		self.virtual_machine = FakeVirtualMachine(vm_id)
		self.uri_translator = RepositoryUriTranslator()

	def setup(self):
		pass

	def teardown(self):
		self.virtual_machine.ssh_call('rm -rf source')
		self.virtual_machine.delete()

	def cache_repository(self, repo_uri):
		return self.virtual_machine.call('true')


class FakeVirtualMachine(VirtualMachine):
	class Instance(object):
		def __init__(self, id):
			self.id = id

	def __init__(self, vm_id):
		super(FakeVirtualMachine, self).__init__(vm_id, FakeVirtualMachine.Instance(vm_id), 'fakeusername')
		self.vm_working_dir = os.path.abspath(os.path.join('/', 'tmp', 'fakevm_%s' % self.instance.id))

	def configure_ssh(self, private_key, output_handler=None):
		return self.call('true')

	def remote_checkout(self, repo_name, repo_url, repo_type, ref, output_handler=None):
		return self.ssh_call('git init %s; cd %s; git fetch %s %s; git checkout FETCH_HEAD' % (repo_name, repo_name, repo_url, ref))

	def provision(self, repo_name, environment, language_config, setup_config, output_handler=None):
		return self.call('true')

	def ssh_call(self, command, output_handler=None, timeout=None):
		command_string = str(command).replace('~', self.vm_working_dir)
		return self.call('bash -c %s' % pipes.quote('mkdir -p %s; cd %s; %s' % (self.vm_working_dir, self.vm_working_dir, command_string)), output_handler, timeout=timeout)

	def scp_call(self, src_fpath, dest_fpath, output_handler=None, timeout=None):
		dest_fpath = os.path.join(self.vm_working_dir, dest_fpath)
		return self.call('cp %s %s' % (pipes.quote(src_fpath), pipes.quote(dest_fpath)))

	def delete(self):
		return self.call('rm -rf %s' %self.vm_working_dir)
