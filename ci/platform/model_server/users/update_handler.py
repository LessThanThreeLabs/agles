import hashlib
import time

from sqlalchemy import and_
from sqlalchemy.exc import IntegrityError

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler


class UsersUpdateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersUpdateHandler, self).__init__("users", "update")

	def add_ssh_pubkey(self, user_id, alias, ssh_key):
		ssh_key = " ".join(ssh_key.split()[:2])  # Retain only type and key
		ssh_pubkey = schema.ssh_pubkey
		timestamp = int(time.time() * 1000)
		ins = ssh_pubkey.insert().values(user_id=user_id, alias=alias, ssh_key=ssh_key, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			try:
				result = sqlconn.execute(ins)
			except IntegrityError:
				if sqlconn.execute(ssh_pubkey.select().where(ssh_pubkey.c.ssh_key == ssh_key)).first():
					raise KeyAlreadyInUseError(ssh_key)
				if sqlconn.execute(ssh_pubkey.select().where(
					and_(
						ssh_pubkey.c.user_id == user_id,
						ssh_pubkey.c.alias == alias))).first():
					raise AliasAlreadyInUseError("user_id: %s, alias: %s" % (user_id, alias))
				raise
		pubkey_id = result.inserted_primary_key[0]
		self.publish_event("users", user_id, "ssh pubkey added", pubkey_id=pubkey_id, alias=alias, ssh_key=ssh_key, timestamp=timestamp)
		return pubkey_id

	def remove_ssh_pubkey(self, user_id, key_id):
		ssh_pubkey = schema.ssh_pubkey
		delete = ssh_pubkey.delete().where(
			and_(
				ssh_pubkey.c.user_id == user_id,
				ssh_pubkey.c.id == key_id
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(delete)
		self.publish_event("users", user_id, "ssh pubkey removed", id=key_id)
		return True

	def remove_ssh_pubkey_by_alias(self, user_id, alias):
		ssh_pubkey = schema.ssh_pubkey
		delete = ssh_pubkey.delete().where(
			and_(
				ssh_pubkey.c.user_id == user_id,
				ssh_pubkey.c.alias == alias
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(delete)
		return True

	def change_basic_information(self, user_id, first_name, last_name):
		user = schema.user
		update = user.update().where(user.c.id == user_id).values(first_name=first_name, last_name=last_name)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user updated", user_id=user_id,
			first_name=first_name, last_name=last_name)
		return True

	def change_password(self, user_id, password_hash, salt):
		user = schema.user
		update = user.update().where(user.c.id == user_id).values(password_hash=password_hash, salt=salt)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user updated", user_id=user_id,
			password_hash=password_hash, salt=salt)
		return True

	def reset_password(self, email, new_password):
		user = schema.user
		salt_query = user.select().where(user.c.email == email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(salt_query).first()
		if row:
			salt = row[user.c.salt]
		else:
			raise NoSuchUserError(email)
		# latin-1 is an arbitrary full-byte fixed length character encoding, which thus does not ruin our original salt
		update = user.update().where(user.c.email == email).values(
			password_hash=hashlib.sha512(salt.encode('latin-1') + new_password.encode('utf8')).hexdigest())
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)


class NoSuchUserError(Exception):
	pass


class KeyAlreadyInUseError(Exception):
	pass


class AliasAlreadyInUseError(Exception):
	pass
