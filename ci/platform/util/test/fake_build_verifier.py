import os
import pipes
import shlex

from database import schema
from database.engine import ConnectionFactory

from verification.build_core import VirtualMachineBuildCore
from virtual_machine.virtual_machine import VirtualMachine
from util.uri_translator import RepositoryUriTranslator


class FakeBuildCore(VirtualMachineBuildCore):
	def __init__(self, vm_id):
		self.virtual_machine = FakeVirtualMachine(vm_id)
		self.uri_translator = RepositoryUriTranslator()

	def setup(self):
		pass

	def setup_build(self, repo_uri, repo_type, ref, private_key, patch_id=None, console_appender=None):
		self.virtual_machine.ssh_call('git init source; cd source; git fetch %s %s; git checkout FETCH_HEAD' % (repo_uri, ref))
		if patch_id:
			patch = schema.patch
			with ConnectionFactory.get_sql_connection() as sqlconn:
				query = patch.select().where(patch.c.id == patch_id)
				row = sqlconn.execute(query).first()
				assert row
				assert row[patch.c.id] == patch_id

				assert self.virtual_machine.ssh_call('cd source && echo %s | patch -p1' % pipes.quote(str(row[patch.c.contents]))).returncode == 0

	def teardown(self):
		self.virtual_machine.ssh_call('rm -rf source')
		self.virtual_machine.delete()

	def cache_repository(self, repo_uri):
		return self.virtual_machine.call(["true"])


class FakeVirtualMachine(VirtualMachine):
	class Instance(object):
		def __init__(self, id):
			self.id = id

	def __init__(self, vm_id):
		super(FakeVirtualMachine, self).__init__(vm_id, FakeVirtualMachine.Instance(vm_id), 'fakeusername')
		self.vm_working_dir = os.path.abspath(os.path.join('/', 'tmp', 'fakevm_%s' % self.instance.id))

	def provision(self, repo_name, private_key, output_handler=None):
		return self.call(["true"])

	def ssh_call(self, command, output_handler=None, timeout=None):
		return self.call(shlex.split('bash -c %s' % pipes.quote('mkdir -p %s; cd %s; %s' % (self.vm_working_dir, self.vm_working_dir, str(command)))), output_handler, timeout=timeout)

	def export(self, export_prefix, files, output_handler=None):
		return self.call(["true"])

	def delete(self):
		return self.call(['rm', '-rf', self.vm_working_dir])
