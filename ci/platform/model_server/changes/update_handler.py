import time

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from settings.web_server import WebServerSettings
from shared.constants import BuildStatus, MergeStatus
from util.mail import sendmail
from util.sql import to_dict

FAILMAIL_TEMPLATE = """%s %s,

There was an issue with the change you submitted so it was not merged.
Please fix the change and resubmit it.

Details for your change are available here: %s

-The Koality Team"""

LAUNCH_TEMPLATE = """%s %s,

Your QA instance has launched. To SSH to it, type the following command into your terminal:

ssh verification@%s "ssh %s"

-The Koality Team"""


class ChangesUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ChangesUpdateHandler, self).__init__("changes", "update")

	def mark_change_started(self, change_id):
		self._update_change_status(change_id, BuildStatus.RUNNING,
			"change started", start_time=int(time.time()))

	def mark_change_finished(self, change_id, verification_status, merge_status=None):
		self._update_change_status(change_id, verification_status,
			"change finished", end_time=int(time.time()), merge_status=merge_status)
		if verification_status == BuildStatus.FAILED or merge_status == MergeStatus.FAILED:
			self._notify_failure(change_id)

	# TODO(andrey) Eventually there needs to be a page in the front end ui containing the currently running QA vm's.
	def mark_qa_build_launched(self, build_id, change_id):
		self._notify_instance_spawned(build_id, change_id)

	def _update_change_status(self, change_id, verification_status, event_name, **kwargs):
		change = schema.change
		commit = schema.commit
		user = schema.user

		update = change.update().where(change.c.id == change_id).values(verification_status=verification_status, **kwargs)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)

		query = change.join(commit).join(user).select().apply_labels().where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		repository_id = row[change.c.repo_id]
		change_number = row[change.c.number]

		user = to_dict(row, user.columns, tablename=user.name)

		if "merge_status" in kwargs:
			self.publish_event("changes", change_id, "merge completed", merge_status=kwargs["merge_status"])
		self.publish_event("repos", repository_id, event_name, change_id=change_id, verification_status=verification_status,
			change_number=change_number, user=user, **kwargs)

	def _get_user_row(self, change_id):
		change = schema.change
		user = schema.user
		commit = schema.commit

		query = change.join(commit).join(user).select(use_labels=True).where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return sqlconn.execute(query).first()

	def _notify_failure(self, change_id):
		row = self._get_user_row(change_id)
		change = schema.change
		user = schema.user

		email = row[user.c.email]
		first_name = row[user.c.first_name]
		last_name = row[user.c.last_name]
		repo_id = row[change.c.repo_id]
		change_number = row[change.c.number]
		change_link = "https://%s/repository/%d?change=%d" % (WebServerSettings.domain_name, repo_id, change_id)

		subject = "There was an issue with your change (#%d)" % change_number
		text = FAILMAIL_TEMPLATE % (first_name, last_name, change_link)

		return sendmail("buildbuddy@koalitycode.com", [email], subject, text)

	def _notify_instance_spawned(self, build_id, change_id):
		row = self._get_user_row(change_id)
		change = schema.change
		user = schema.user

		email = row[user.c.email]
		first_name = row[user.c.first_name]
		last_name = row[user.c.last_name]

		subject = "Your QA instance has spawned"
		text = LAUNCH_TEMPLATE % (first_name, last_name, WebServerSettings.domain_name, build_id)

		return sendmail("buildbuddy@koalitycode.com", [email], subject, text)

	def add_export_uris(self, change_id, export_uris):
		if not export_uris:
			return

		change_export_uri = schema.change_export_uri

		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(
				change_export_uri.insert(),
				[{'change_id': change_id, 'uri': uri} for uri in export_uris]
			)

		self.publish_event("changes", change_id, "export uris added", export_uris=export_uris)
