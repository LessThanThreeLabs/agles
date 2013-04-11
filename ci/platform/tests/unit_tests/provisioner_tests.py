import os

from nose.tools import *
from util.test import BaseUnitTest
from provisioner.provisioner import Provisioner


class ProvisionerTest(BaseUnitTest):
	def setUp(self):
		self.provisioner = Provisioner()
		self.repo_root = os.path.abspath(os.path.join(__file__, os.path.pardir, os.path.pardir, os.path.pardir, os.path.pardir, os.path.pardir))
		self.yaml_path = os.path.join(self.repo_root, 'koality.yml')

	def test_path_resolution(self):
		resolved_by_config = self.provisioner.resolve_paths(config_path=self.yaml_path)
		resolved_by_source = self.provisioner.resolve_paths(source_path=self.repo_root)

		assert_equal(resolved_by_source, resolved_by_config)
		assert_equal(self.yaml_path, resolved_by_source[0])
		assert_equal(self.repo_root, resolved_by_source[1])

	def test_read_config(self):
		config = self.provisioner.read_config(self.yaml_path)

		assert_true(config)
		assert_in('languages', config)
		assert_in('setup', config)
		assert_in('compile', config)
		assert_in('test', config)
		assert_in('partition', config)

	def test_parse_config(self):
		config = self.provisioner.read_config(self.yaml_path)
		steps = self.provisioner.parse_config(config, self.repo_root, global_install=True)
		for action_name, step in steps:
			assert_is_instance(action_name, str)
		language_steps, setup_steps = steps
		assert_true(len(setup_steps[1].setup_steps) > 0)
		assert_true(len(setup_steps[1].get_script_contents()) > 0)
