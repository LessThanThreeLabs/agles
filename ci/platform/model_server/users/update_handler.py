import hashlib
import time

from sqlalchemy import and_
from sqlalchemy.exc import IntegrityError

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import AdminApi, InvalidPermissionsError


class UsersUpdateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersUpdateHandler, self).__init__("users", "update")

	def add_ssh_pubkeys(self, user_id, alias_to_pubkey_map):
		timestamp = int(time.time())
		errors = []
		ids = []
		for alias, pubkey in alias_to_pubkey_map.items():
			try:
				ids.append(self._add_ssh_pubkey(user_id, alias, pubkey, timestamp))
			except (KeyAlreadyInUseError, AliasAlreadyInUseError) as e:
				errors.append(e)
		if len(errors) > 0:
			raise errors[0]
		else:
			return ids

	def _add_ssh_pubkey(self, user_id, alias, pubkey, timestamp):
		pubkey = ' '.join(pubkey.split()[:2])
		ssh_pubkey = schema.ssh_pubkey
		ins = ssh_pubkey.insert().values(user_id=user_id, alias=alias, ssh_key=pubkey, timestamp=timestamp)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			try:
				result = sqlconn.execute(ins)
			except IntegrityError:
				if sqlconn.execute(ssh_pubkey.select().where(ssh_pubkey.c.ssh_key == pubkey)).first():
					raise KeyAlreadyInUseError(pubkey)
				if sqlconn.execute(ssh_pubkey.select().where(
					and_(
						ssh_pubkey.c.user_id == user_id,
						ssh_pubkey.c.alias == alias))).first():
					raise AliasAlreadyInUseError("user_id: %s, alias: %s" % (user_id, alias))
				raise
		pubkey_id = result.inserted_primary_key[0]
		self.publish_event("users", user_id, "ssh pubkey added", id=pubkey_id, alias=alias, ssh_key=pubkey, timestamp=timestamp)
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

	@AdminApi
	def set_admin(self, user_id, user_id_to_change, admin):
		user = schema.user

		if user_id == user_id_to_change:
			raise InvalidPermissionsError(user_id, user_id_to_change)

		update = user.update().where(user.c.id == user_id_to_change).values(admin=admin)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user admin status", user_id=user_id_to_change, admin=admin)

	def change_basic_information(self, user_id, first_name, last_name):
		user = schema.user
		update = user.update().where(user.c.id == user_id).values(first_name=first_name, last_name=last_name)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user name updated", user_id=user_id,
			first_name=first_name, last_name=last_name)
		return True

	def change_password(self, user_id, password_hash, salt):
		user = schema.user
		update = user.update().where(user.c.id == user_id).values(password_hash=password_hash, salt=salt)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user password updated", user_id=user_id,
			password_hash=password_hash, salt=salt)
		return True

	def change_github_oauth_token(self, user_id, github_oauth_token):
		user = schema.user
		update = user.update().where(user.c.id == user_id).values(github_oauth=github_oauth_token)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event("users", user_id, "user github oauth token updated", user_id=user_id,
			github_oauth_token=github_oauth_token)
		return True


class NoSuchUserError(Exception):
	pass


class KeyAlreadyInUseError(Exception):
	pass


class AliasAlreadyInUseError(Exception):
	pass
