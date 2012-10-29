assert = require 'assert'
nodemailer = require 'nodemailer'


exports.create = (configurationParams, domainName) ->
	createAccountEmailer = new CreateAccountEmailer configurationParams, domainName
	createAccountEmailer.initialize()
	return createAccountEmailer


class CreateAccountEmailer
	constructor: (@configurationParams, @domainName) ->
		assert.ok @configurationParams? and @domainName?


	initialize: () =>
		@mailTransport = nodemailer.createTransport 'SMTP',
			service: @configurationParams.service
			auth:
				user: @configurationParams.authorization.username
				pass: @configurationParams.authorization.password


	sendEmailToUser: (firstName, lastName, email, key, callback) =>
		verifyUrl =  @domainName + '/verifyAccount?account=' + key

		mailOptions = 
			from: @configurationParams.from
			to: firstName + ' ' + lastName + ' <' + email + '>'
			subject: 'Verify your account!'
			generateTextFromHTML: true
			html: "Click to verify your account: <a href='#{verifyUrl}'>#{verifyUrl}</a>"

		@mailTransport.sendMail mailOptions, (error, response) =>
			console.error 'error in createAccountEmailer: ' + JSON.stringify(error) if error?
			callback error, response if callback?
