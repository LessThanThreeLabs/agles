import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import is_admin, InvalidPermissionsError


class UsersDeleteHandler(ModelServerRpcHandler):
	def __init__(self):
		super(UsersDeleteHandler, self).__init__("users", "delete")

	def delete_user(self, user_id, user_to_delete_id):
		user = database.schema.user

		if not is_admin(user_id):
			raise InvalidPermissionsError(user_id, user_to_delete_id)
		if user_id == user_to_delete_id:
			raise InvalidPermissionsError(user_id, user_to_delete_id)

		update = user.update().where(user.c.id == user_to_delete_id).values(deleted=user_to_delete_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event_to_admins("users", "user removed", removed_id=user_to_delete_id)
