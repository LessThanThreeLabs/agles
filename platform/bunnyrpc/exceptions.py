"""exceptions.py - contains BunnyRPC exceptions"""

class RPCError(Exception):
	def __init__(self, msg=''):
		super(RPCError, self).__init__(msg)

class RPCRequestError(RPCError):
	def __init__(self, msg=''):
		super(RPCRequestError, self).__init__(msg)