import os

import model_server

from util.log import Logged


@Logged()
class PubkeyRegistrar(object):
	def register_pubkey(self, user_id, alias, pubkey=None):
		if not pubkey:
			pubkey = self.get_ssh_pubkey()
		try:
			with model_server.rpc_connect("users", "update") as users_update_rpc:
				users_update_rpc.add_ssh_pubkey(user_id, alias, pubkey)
		except:
			self.logger.warn("Could not register pubkey %s for user %d with alias %s" % (pubkey, user_id, alias))

	def unregister_pubkey(self, user_id, alias):
		try:
			with model_server.rpc_connect("users", "update") as users_update_rpc:
				users_update_rpc.remove_ssh_pubkey_by_alias(user_id, alias)
		except:
			self.logger.warn("Could not unregister pubkey for user %d with alias %s" % (user_id, alias))

	def get_ssh_pubkey(self):
		with open(os.path.join(os.path.join(os.environ["HOME"], ".ssh"), "id_rsa.pub")) as pubkey_file:
			return pubkey_file.read()
