from nose.tools import *
from util.permissions import RepositoryPermissions

from util.test import BaseUnitTest


class ShellTest(BaseUnitTest):
	def setUp(self):
		pass

	def tearDown(self):
		pass

	def test_has_permissions(self):
		assert_true(RepositoryPermissions.has_permissions(RepositoryPermissions.RWA, RepositoryPermissions.RWA))
		assert_true(RepositoryPermissions.has_permissions(RepositoryPermissions.RWA, RepositoryPermissions.RW))
		assert_true(RepositoryPermissions.has_permissions(RepositoryPermissions.RWA, RepositoryPermissions.R))
		assert_true(RepositoryPermissions.has_permissions(RepositoryPermissions.RW, RepositoryPermissions.RW))
		assert_true(RepositoryPermissions.has_permissions(RepositoryPermissions.RW, RepositoryPermissions.R))
		assert_true(RepositoryPermissions.has_permissions(RepositoryPermissions.R, RepositoryPermissions.R))

		assert_false(RepositoryPermissions.has_permissions(RepositoryPermissions.RW, RepositoryPermissions.RWA))
		assert_false(RepositoryPermissions.has_permissions(RepositoryPermissions.R, RepositoryPermissions.RW))
		assert_false(RepositoryPermissions.has_permissions(RepositoryPermissions.R, RepositoryPermissions.RWA))
