import hashlib
import database.schema
import util.pathgen

from database.engine import ConnectionFactory
from model_server.mediastore import S3MediaStore
from model_server.rpc_handler import ModelServerRpcHandler
from settings.aws.s3 import media_bucket


class UserCreateHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UserCreateHandler, self).__init__("user", "create")
		self.mediastore = S3MediaStore(media_bucket)

	def upload_media(self, media_binary):
		media = database.schema.media

		md5hash = hashlib.md5(media_binary).hexdigest()
		ins = media.insert().values(hash=md5hash)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			media_id = sqlconn.execute(ins).inserted_primary_key

		path = self._generate_path(media_id, md5hash)
		self.mediastore.store_media(media_binary, path)

	def _generate_path(self, media_id, hash):
		return util.pathgen.to_path(hash, media_id)