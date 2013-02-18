assert = require 'assert'
Mailgun = require('mailgun').Mailgun


exports.create = (configurationParams) ->
	inviteUserEmailer = new InviteUserEmailer configurationParams
	return inviteUserEmailer


class InviteUserEmailer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?
		@emailer = new Mailgun @configurationParams.emailer.mailgun.key


	inviteUser: (email, userToken, callback) =>
		uri = 'https://' + @configurationParams.domain + '/create/account?token=' + userToken
		@emailer.sendText @configurationParams.createAccount.email.from, email,
			'Welcome to Koality!', "Click here to create your account: #{uri}", (error) ->
				console.error error if error?
				callback error if callback?
