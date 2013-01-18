from sqlalchemy import and_
from sqlalchemy.exc import IntegrityError

import database.schema
import repo.store

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.permissions import RepositoryPermissions, InvalidPermissionsError


class ReposUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ReposUpdateHandler, self).__init__("repos", "update")

	def update_description(self, user_id, repo_id, description):
		permission = database.schema.permission

		row = self._get_repo_permissions(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		update = repo.update().where(repo.c.id==repo_id).values(description=description)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)

		self.publish_event("repos", repo_id, "description updated", description=description)

	def add_member(self, user_id, email, repo_id):
		repo = database.schema.repo
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_permissions(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(repo.select().where(repo.c.id==repo_id)).first()
			if not row:
				raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))
			repo_permissions = row[repo.c.default_permissions]
			invited_user = sqlconn.execute(user.select().where(user.c.email==email)).first()
			if not invited_user:
				raise NoSuchUserError("email: %s" % email)
			invited_user_id = invited_user[user.c.id]
			sqlconn.execute(permission.insert().values(user_id=invited_user_id, repo_id=repo_id, permissions=repo_permissions))

		self.publish_event("repos", repo_id, "member added", email=email, first_name=invited_user[user.c.first_name],
			last_name=invited_user[user.c.last_name], permissions=repo_permissions)

	# TODO: Should this delete/add or update/insert?
	def change_member_permissions(self, user_id, email, repo_id, permissions):
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_permissions(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		user_query = user.select().where(user.c.email==email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			user_row = sqlconn.execute(user_query).first()
		if not user_row:
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		target_user_id = user_row[user.c.id]
		if target_user_id == user_id:
			raise InvalidActionError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		del_query = permission.delete().where(and_(
			permission.c.user_id==target_user_id,
			permission.c.repo_id==repo_id)
		)
		ins = permission.insert().values(user_id=target_user_id, repo_id=repo_id, permissions=permissions)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(del_query)
			sqlconn.execute(ins)

		self.publish_event("repos", repo_id, "member permissions changed", email=email, permissions=permissions)

	def remove_member(self, user_id, email, repo_id):
		user = database.schema.user
		permission = database.schema.permission

		row = self._get_repo_permissions(user_id, repo_id)
		if not row or not RepositoryPermissions.has_permissions(
				row[permission.c.permissions], RepositoryPermissions.RWA):
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		user_query = user.select().where(user.c.email==email)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			user_row = sqlconn.execute(user_query).first()
		if not user_row:
			raise InvalidPermissionsError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		target_user_id = user_row[user.c.id]
		if target_user_id == user_id:
			raise InvalidActionError("user_id: %d, repo_id: %d" % (user_id, repo_id))

		del_query = permission.delete().where(
			and_(
				permission.c.user_id==target_user_id,
				permission.c.repo_id==repo_id
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(del_query)

		self.publish_event("repos", repo_id, "member removed", email=email)

	def _get_repo_permissions(self, user_id, repo_id):
		permission = database.schema.permission

		query = permission.select().where(
			and_(
				permission.c.repo_id==repo_id,
				permission.c.user_id==user_id
			)
		)

		with ConnectionFactory.get_sql_connection() as sqlconn:
			return sqlconn.execute(query).first()

	def update_repostore(self, repostore_id, host_name, root_dir, num_repos):
		repostore = database.schema.repostore
		query = repostore.select().where(repostore.c.id==repostore_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			assert row[repostore.c.host_name] == host_name
			assert row[repostore.c.repositories_path] == root_dir

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.register_remote_store(repostore_id, num_repos=num_repos)

	def force_push(self, repo_id, user_id, target):
		schema = database.schema
		query = schema.repo.select().where(schema.repo.c.id==repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			assert row is not None
			repostore_id = row[schema.repo.c.repostore_id]
			repo_name = row[schema.repo.c.name]

		manager = repo.store.DistributedLoadBalancingRemoteRepositoryManager(ConnectionFactory.get_redis_connection())
		manager.push_force(repostore_id, repo_id, repo_name, target)

	def set_forward_url(self, user_id, repo_id, forward_url):
		repo = database.schema.repo

		# A repo should already exist
		update = repo.update().where(repo.c.id==repo_id).values(forward_url=forward_url)
		with ConnectionFactory.get_sql_connection() as sqlconn:
				sqlconn.execute(update)
		self.publish_event("repos", repo_id, "forward url updated", forward_url=forward_url)


class NoSuchUserError(Exception):
	pass


class InvalidActionError(Exception):
	pass
