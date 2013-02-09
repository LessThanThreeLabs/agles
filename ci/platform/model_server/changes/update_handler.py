import time

from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from shared.constants import BuildStatus
from util.mail import sendmail

FAILMAIL_TEMPLATE = """%s %s,

There was an issue with the change you submitted so it was not merged.
Please fix the change and resubmit it.

Details for your change are available here: %s

-The Koality Team"""


class ChangesUpdateHandler(ModelServerRpcHandler):

	def __init__(self):
		super(ChangesUpdateHandler, self).__init__("changes", "update")

	def mark_change_started(self, change_id):
		self._update_change_status(change_id, BuildStatus.RUNNING,
			"change started", start_time=int(time.time()))

	def mark_change_finished(self, change_id, status):
		self._update_change_status(change_id, status,
			"change finished", end_time=int(time.time()))
		if status == BuildStatus.FAILED:
			self._notify_failure(change_id)

	def _update_change_status(self, change_id, status, event_name, **kwargs):
		change = schema.change
		update = change.update().where(change.c.id == change_id).values(status=status, **kwargs)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			sqlconn.execute(update)

		query = change.select().where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		repository_id = row[change.c.repo_id]

		self.publish_event("repos", repository_id, event_name, change_id=change_id, status=status, **kwargs)

	def _notify_failure(self, change_id):
		change = schema.change
		commit = schema.commit
		user = schema.user

		query = change.join(commit).join(user).select(use_labels=True).where(change.c.id == change_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			row = sqlconn.execute(query).first()
		email = row[user.c.email]
		first_name = row[user.c.first_name]
		last_name = row[user.c.last_name]
		repo_id = row[change.c.repo_id]
		change_number = row[change.c.number]
		change_link = "https://getkoality.com/repository/%d/changes/%d/home" % (repo_id, change_id)

		subject = "There was an issue with your change (#%d)" % change_number
		text = FAILMAIL_TEMPLATE % (first_name, last_name, change_link)

		return sendmail("buildbuddy@getkoality.com", [email], subject, text)
