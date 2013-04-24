import binascii

from Crypto.Cipher import AES


system_settings_cipher = AES.new(binascii.unhexlify('6B9945583AF2F9DE00D9EF1FABCCFA30CF84AA4E855E12DC448B277D7C65D90F'))
