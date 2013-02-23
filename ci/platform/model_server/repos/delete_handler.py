import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import is_admin, InvalidPermissionsError


class ReposDeleteHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ReposDeleteHandler, self).__init__("repos", "delete")

	def delete_repo(self, user_id, repo_id):
		repo = database.schema.repo

		if not is_admin(user_id):
			raise InvalidPermissionsError(user_id, repo_id)

		update = repo.update().where(repo.c.id == repo_id).values(deleted=repo_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
