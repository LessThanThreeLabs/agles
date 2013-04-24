import base64
import yaml


class CryptoYaml(object):
	def __init__(self, cipher):
		self.cipher = cipher

	def dump(self, setting):
		return base64.encodestring(self.cipher.encrypt(self._pad(yaml.safe_dump(setting))))

	def load(self, setting):
		return yaml.safe_load(self.cipher.decrypt(base64.decodestring(setting)))

	def _pad(self, setting):
		return setting + ((self.cipher.block_size - len(setting) % self.cipher.block_size) * '\n')
