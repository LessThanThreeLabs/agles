""" permissions.py - utility classes for handling permissions"""

class Permissions(object):
	pass

class RepositoryPermissions(Permissions):
	""" Permissions are currently stored as bitmasks. These methods should be
	used to operate on the bitmasks to do comparisons and permissions checks.
	"""

	R = 0b1
	RW = 0b11
	RWA = 0b111

	@classmethod
	def has_permissions(cls, permissions, permissions_to_check):
		return (permissions & permissions_to_check) == permissions_to_check
