import time

from shared.constants import MAX_SPECIAL_USER_ID
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

Branch:
%s

Commit Message:
%s

-The Koality Team
https://koalitycode.com"""


class ChangesUpdateHandler(ModelServerRpcHandler):

	def __init__(self, channel=None):
		super(ChangesUpdateHandler, self).__init__("changes", "update", channel)

	def mark_change_started(self, change_id):
		self._update_change_status(change_id, BuildStatus.RUNNING,
			"change started", start_time=int(time.time()))

	def mark_change_finished(self, change_id, verification_status, merge_status=None):
		self._update_change_status(change_id, verification_status,
			"change finished", end_time=int(time.time()), merge_status=merge_status)
		if verification_status == BuildStatus.FAILED or merge_status == MergeStatus.FAILED:
			self._notify_failure(change_id)

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
		commit = to_dict(row, commit.columns, tablename=commit.name)

		if "merge_status" in kwargs:
			self.publish_event("changes", change_id, "merge completed", merge_status=kwargs["merge_status"])
		self.publish_event("repos", repository_id, event_name, change_id=change_id, verification_status=verification_status,
			change_number=change_number, user=user, commit=commit, **kwargs)

	def _notify_failure(self, change_id):
		change = schema.change
		commit = schema.commit
		user = schema.user

		query = change.join(commit).join(user).select(use_labels=True).where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()

		email = row[user.c.email] if user.c.id <= MAX_SPECIAL_USER_ID else row[commit.c.committer_email]

		first_name = row[user.c.first_name]
		last_name = row[user.c.last_name]
		repo_id = row[change.c.repo_id]
		target = row[change.c.merge_target]
		sha = row[commit.c.sha]
		message = row[commit.c.message]
		change_link = "https://%s/repository/%d?change=%d" % (WebServerSettings.domain_name, repo_id, change_id)

		subject = "There was an issue with your change (%s)" % sha
		text = FAILMAIL_TEMPLATE % (first_name, last_name, change_link, target, message)

		return sendmail("koality@%s" % WebServerSettings.domain_name, [email], subject, text)
