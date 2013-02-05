import hashlib
import database.schema
import util.pathgen

from sqlalchemy.exc import IntegrityError

from database.engine import ConnectionFactory
from model_server.mediastore import S3MediaStore
from model_server.rpc_handler import ModelServerRpcHandler
from settings.aws.s3 import S3Settings


class UsersCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersCreateHandler, self).__init__("users", "create")
		self.mediastore = S3MediaStore(S3Settings.media_bucket)

	def upload_media(self, media_binary):
		media = database.schema.media

		md5hash = hashlib.md5(media_binary).hexdigest()
		ins = media.insert().values(hash=md5hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			media_id = sqlconn.execute(ins).inserted_primary_key

		path = self._generate_path(media_id, md5hash)
		self.mediastore.store_media(media_binary, path)

	def create_user(self, email, first_name, last_name, password_hash, salt):
		user = database.schema.user
		ins = user.insert().values(email=email, first_name=first_name, last_name=last_name, password_hash=password_hash, salt=salt)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			try:
				result = sqlconn.execute(ins)
			except IntegrityError:
				raise UserAlreadyExistsError(email)

		user_id = result.inserted_primary_key[0]
		self.publish_event("global", None, "user created", user_id=user_id, email=email, first_name=first_name, last_name=last_name,
			password_hash=password_hash, salt=salt)
		return user_id

	def _generate_path(self, media_id, hash):
		return util.pathgen.to_path(hash, media_id)


class UserAlreadyExistsError(Exception):
	pass
