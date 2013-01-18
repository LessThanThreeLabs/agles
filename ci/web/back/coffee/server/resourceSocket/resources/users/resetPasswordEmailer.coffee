assert = require 'assert'
nodemailer = require 'nodemailer'


exports.create = (configurationParams, domainName) ->
	resetPasswordEmailer = new ResetPasswordEmailer configurationParams, domainName
	resetPasswordEmailer.initialize()
	return resetPasswordEmailer


class ResetPasswordEmailer
	constructor: (@configurationParams, @domainName) ->
		assert.ok @configurationParams? and @domainName?


	initialize: () =>
		@mailTransport = nodemailer.createTransport 'SMTP',
			service: @configurationParams.service
			auth:
				user: @configurationParams.authorization.username
				pass: @configurationParams.authorization.password


	sendEmailToUser: (email, newPassword, callback) =>
		mailOptions = 
			from: @configurationParams.from
			to: email
			subject: 'Your new Koality password!'
			generateTextFromHTML: true
			html: "Your new password is: #{newPassword}"

		@mailTransport.sendMail mailOptions, (error, response) =>
			console.error 'error in resetPasswordEmailer: ' + JSON.stringify(error) if error?
			callback error, response if callback?
