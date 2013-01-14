from nose.tools import *
from util.test import BaseUnitTest
from util.pathgen import directory_treeify, to_path


class ShellTest(BaseUnitTest):
	def setUp(self):
		pass

	def tearDown(self):
		pass

	def test_directory_treeify(self):
		evenlen_hash = '1234567890'
		assert_equal('12/34/567890', directory_treeify(evenlen_hash))
		assert_equal('12/34/56/7890', directory_treeify(evenlen_hash, dir_levels=4))
		assert_raises(AssertionError, directory_treeify, evenlen_hash, -1)

		oddlen_hash = '123456789'
		assert_equal('12/34/56789', directory_treeify(oddlen_hash))
		assert_equal('12/34/56/789', directory_treeify(oddlen_hash, dir_levels=4))

	def test_to_path(self):
		evenlen_hash = '1234567890'
		name = 'repo.git'
		assert_equal('12/34/567890/repo.git', to_path(evenlen_hash, name))
