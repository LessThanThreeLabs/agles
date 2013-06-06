import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import AdminApi
from util.sql import to_dict


class ReposDeleteHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposDeleteHandler, self).__init__("repos", "delete")

	@AdminApi
	def delete_repo(self, user_id, repo_id):
		self._delete_repo(repo_id)

	def _delete_repo(self, repo_id):
		repo = database.schema.repo

		update = repo.update().where(repo.c.id == repo_id).values(deleted=repo_id)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)
		self.publish_event_to_all("users", "repository removed", repo_id=repo_id)

	def truncate_repositories(self, max_repository_count):
		if max_repository_count is None:
			return

		assert max_repository_count >= 0

		repo = database.schema.repo

		query = repo.select().apply_labels().where(repo.c.deleted == 0)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)
		repositories = map(lambda row: to_dict(row, repo.columns, tablename=repo.name), rows)

		repositories = sorted(repositories, key=lambda repo: repo['id'])

		to_delete = map(lambda repo: repo['id'], repositories[max_repository_count:])

		for repo_id in to_delete:
			self._delete_repo(repo_id)
