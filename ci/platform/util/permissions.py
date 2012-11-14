""" permissions.py - utility classes for handling permissions"""

class Permissions(object):
	pass

class RepositoryPermissions(Permissions):
	""" Permissions are currently stored as bitmasks. These methods should be
	used to operate on the bitmasks to do comparisons and permissions checks.
	"""
	NONE = 0
	R = 0b1
	RW = 0b11
	RWA = 0b111

	@classmethod
	def has_permissions(cls, given_permissions, required_permissions):
		return (given_permissions & required_permissions) == required_permissions

	@classmethod
	def valid_permissions(cls):
		return [cls.NONE, cls.R, cls.RW, cls.RWA]