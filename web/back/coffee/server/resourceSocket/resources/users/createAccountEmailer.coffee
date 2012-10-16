assert = require 'assert'
nodemailer = require 'nodemailer'


exports.create = (configurationParams) ->
	createAccountEmailer = new CreateAccountEmailer configurationParams
	createAccountEmailer.initialize()
	return createAccountEmailer


class CreateAccountEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	initialize: () =>
		@mailTransport = nodemailer.createTransport 'SMTP',
			service: 'Gmail'
			auth:
				user: @configurationParams.authorization.username
				pass: @configurationParams.authorization.password


	sendEmailToUser = (firstName, lastName, email) ->
		mailOptions = 
			from: @configurationParams.from
			to: firstName + ' ' + lastName + ' <' + email + '>'
			subject: 'Verify your account!'
			text: 'nerd up!'
			html: '<b>nerd up!</b>'

		mailTransport.sendMail mailOptions, (error, response) ->
			console.error 'error: ' + JSON.stringify(error) if error?
