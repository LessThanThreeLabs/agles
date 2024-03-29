from database import schema
from database.engine import ConnectionFactory
from model_server.rpc_handler import ModelServerRpcHandler
from settings.web_server import WebServerSettings
from util.mail import sendmail

# TODO (akostov): make this timeout not hardcoded
LAUNCH_TEMPLATE = """%s %s,

Your debug instance has launched and will be accessible for the next %s minutes.

To SSH into your debug instance type the following command into your terminal:

ssh verification@%s -Ct "ssh %s"

-The Koality Team"""


class DebugInstancesUpdateHandler(ModelServerRpcHandler):

	def __init__(self, channel=None):
		super(DebugInstancesUpdateHandler, self).__init__("debug_instances", "update", channel)

	# TODO(andrey) Eventually there needs to be a page in the front end ui containing the currently running debug vm's.
	def mark_debug_instance_launched(self, instance_id, user_id, duration):
		self._notify_instance_spawned(instance_id, user_id, duration)

	def _get_user_row(self, user_id):
		user = schema.user

		query = user.select().where(user.c.id == user_id)
		with ConnectionFactory.get_sql_connection() as sqlconn:
			return sqlconn.execute(query).first()

	def _notify_instance_spawned(self, instance_id, user_id, duration):
		row = self._get_user_row(user_id)
		user = schema.user

		email = row[user.c.email]
		first_name = row[user.c.first_name]
		last_name = row[user.c.last_name]

		subject = "Your debug instance has launched"
		text = LAUNCH_TEMPLATE % (first_name, last_name, duration/60, WebServerSettings.domain_name, instance_id)

		return sendmail("koality@%s" % WebServerSettings.domain_name, [email], subject, text)
