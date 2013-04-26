from sqlalchemy import and_

import database.schema

from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from util.sql import to_dict


class ReposReadHandler(ModelServerRpcHandler):
	def __init__(self):
		super(ReposReadHandler, self).__init__("repos", "read")

	def get_repo_uri(self, commit_id):
		commit = database.schema.commit
		repo = database.schema.repo

		repo_id_query = commit.select().where(
			commit.c.id == commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(repo_id_query).first()
		if not row:
			return None
		repo_id = row[commit.c.repo_id]

		query = repo.select().where(repo.c.id == repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.uri] if row else None

	def get_repo_name(self, repo_id):
		repo = database.schema.repo
		query = repo.select().where(repo.c.id == repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[repo.c.name] if row else None

	def get_repo_attributes(self, requested_repo_uri):
		repo = database.schema.repo
		repostore = database.schema.repostore

		query = repo.join(repostore).select().apply_labels().where(
			and_(
				repo.c.uri == requested_repo_uri,
				repo.c.deleted == 0
			)
		)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row_result = sqlconn.execute(query).first()
		if not row_result:
			return None
		return row_result[repostore.c.id], row_result[repostore.c.ip_address], row_result[repostore.c.repositories_path], row_result[repo.c.id], row_result[repo.c.name], row_result[repo.c.privatekey]

	def get_user_id_from_public_key(self, key):
		ssh_pubkey = database.schema.ssh_pubkey
		query = ssh_pubkey.select().where(ssh_pubkey.c.ssh_key == key)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		return row[ssh_pubkey.c.user_id] if row else None

	def get_commit_attributes(self, commit_id):
		commit = database.schema.commit

		query = commit.select().where(commit.c.id == commit_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		if row:
			return to_dict(row, commit.columns)
		else:
			return None

	#################
	# Front end API #
	#################

	def get_repositories(self, user_id):
		repo = database.schema.repo

		query = repo.select().apply_labels().where(repo.c.deleted == 0)  # Check to make sure its not deleted
		with ConnectionFactory.get_sql_connection() as sqlconn:
			rows = sqlconn.execute(query)
		return map(lambda row: to_dict(row, repo.columns, tablename=repo.name), rows)

	def get_repo_from_id(self, user_id, repo_id):
		repo = database.schema.repo

		query = repo.select().where(repo.c.id == repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		assert row is not None
		return to_dict(row, repo.columns)

	def can_hear_repository_events(self, user_id, id_to_listen_to):
		return True

#########################
# Host Repo Integration #
#########################

	def get_repo_forward_url(self, repo_id):
		repo = database.schema.repo

		query = repo.select().where(repo.c.id == repo_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
			return row[repo.c.forward_url] if row else None
