import unittest

from nose.tools import *
from util.pathgen import directory_treeify, to_path

class ShellTest(unittest.TestCase):
	def setUp(self):
		pass

	def tearDown(self):
		pass

	def test_directory_treeify(self):
		evenlen_hash = '1234567890'
		assert_equals('12/34/567890', directory_treeify(evenlen_hash))
		assert_equals('12/34/56/7890', directory_treeify(evenlen_hash, dir_levels=4))
		assert_raises(AssertionError, directory_treeify, evenlen_hash, -1)

		oddlen_hash = '123456789'
		assert_equals('12/34/56789', directory_treeify(oddlen_hash))
		assert_equals('12/34/56/789', directory_treeify(oddlen_hash, dir_levels=4))

		undersized_hash = '123'
		assert_raises(AssertionError, directory_treeify, undersized_hash)

	def test_to_path(self):
		evenlen_hash = '1234567890'
		name = 'repo.git'
		assert_equals('12/34/567890/repo.git', to_path(evenlen_hash, name))