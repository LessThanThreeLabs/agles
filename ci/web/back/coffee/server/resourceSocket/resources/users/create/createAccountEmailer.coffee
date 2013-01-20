assert = require 'assert'
Mailgun = require('mailgun').Mailgun


exports.create = (configurationParams) ->
	createAccountEmailer = new CreateAccountEmailer configurationParams
	return createAccountEmailer


class CreateAccountEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?
		@emailer = new Mailgun @configurationParams.emailer.mailgun.key


	sendEmailToUser: (firstName, lastName, email, key, callback) =>
		verifyUrl =  @configurationParams.domain + '/verifyAccount?account=' + key

		@emailer.sendText @configurationParams.createAccount.email.from, "#{firstName} #{lastName} <#{email}>",
			'Verify your account!', "Click to verify your account: #{verifyUrl}", (error) ->
				console.error error if error?
				callback error if callback?
				