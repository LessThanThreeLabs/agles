import requests

from settings.mail import API_URL, API_KEY, TEST_MODE


def sendmail(send_from, send_to, subject, text, cc=None, bcc=None, html=None, attachment=None, testmode=TEST_MODE):
	response = requests.post(
		API_URL,
		auth=("api", API_KEY),
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
