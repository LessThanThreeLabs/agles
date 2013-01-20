assert = require 'assert'
https = require 'https'


exports.create = (configurationParams) ->
	createAccountEmailer = new CreateAccountEmailer configurationParams
	return createAccountEmailer


class CreateAccountEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	sendEmailToUser: (firstName, lastName, email, key, callback) =>
		verifyUrl =  @configurationParams.domain + '/verifyAccount?account=' + key

		mailOptions =
			hostname: @configurationParams.emailer.mailgun.hostname
			port: @configurationParams.emailer.mailgun.port
			path: @configurationParams.emailer.mailgun.path
			method: @configurationParams.emailer.mailgun.method
			headers:
				from: @configurationParams.createAccount.email.from
				to: firstName + ' ' + lastName + ' <' + email + '>'
				subject: 'Verify your account!'
				html: "Click to verify your account: <a href='#{verifyUrl}'>#{verifyUrl}</a>"
				o:testmode: @configurationParams.emailer.mailgun.testMode

		https.request mailOptions, (response) =>
			callback() if callback?
