import gevent
import zerorpc

from settings.verification_server import bind_address


class VerificationServer(object):
	"""Manages and routes requests for verification of builds"""

	DEFAULT_RPC_TIMEOUT = 500

	@classmethod
	def get_connection(cls):
		return zerorpc.Client(bind_address, timeout=cls.DEFAULT_RPC_TIMEOUT)

	def __init__(self):
		pass

	def verify(self, repo_hash, sha, ref):
		# get committer and user, write into db the repo, sha, ref, etc
		pass
