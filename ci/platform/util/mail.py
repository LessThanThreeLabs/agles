import requests

from settings.mail import MailSettings


def sendmail(send_from, send_to, subject, text, cc=None, bcc=None, html=None, attachment=None, testmode=MailSettings.test_mode):
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

	return response
