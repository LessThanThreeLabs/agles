import logging
import requests

from settings.mail import MailSettings
from util.log import configure


def sendmail(send_from, send_to, subject, text, cc=None, bcc=None, html=None, attachment=None, testmode=None):
	if testmode is None:
		testmode = MailSettings.test_mode
	if testmode is True:
		return True

	configure()
	logging.getLogger("Mailer").debug(_log_string('Sending mail', send_from, send_to, subject, testmode))
	response = requests.post(
		MailSettings.api_url,
		auth=("api", MailSettings.api_key),
		data={
			"from": send_from,
			"to": send_to,
			"subject": subject,
			"text": text,
			"cc": cc,
			"bcc": bcc,
			"html": html,
			"attachment": attachment,
			"o:testmode": testmode
		}
	)
	if not response.ok:
		logging.getLogger("Mailer").error(_log_string('Unable to send mail', send_from, send_to, subject, testmode))

	return response


def _log_string(prefix, send_from, send_to, subject, testmode):
	return "%s %s->%s, subject: %s%s" % (prefix, send_from, send_to, subject, ', testmode=True' if testmode else '')
