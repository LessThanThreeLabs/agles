import os

from model_server import ModelServer


class PubkeyRegistrar(object):
	def register_pubkey(self, user_id, alias):
		try:
			with ModelServer.rpc_connect("users", "update") as users_update_rpc:
				users_update_rpc.add_ssh_pubkey(user_id, alias, self.get_ssh_pubkey())
		except:
			pass

	def get_ssh_pubkey(self):
		with open(os.path.join(os.path.join(os.environ["HOME"], ".ssh"), "id_rsa.pub")) as pubkey_file:
			return pubkey_file.read()
