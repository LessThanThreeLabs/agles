assert = require 'assert'


exports.create = (configurationParams, domain, emailer) ->
	return new InviteUserEmailer configurationParams, domain, emailer


class InviteUserEmailer
	constructor: (@configurationParams, @domain, @emailer) ->
		assert.ok @configurationParams?
		assert.ok @domain?
		assert.ok @emailer?


	email: (toEmail, userToken, callback) =>
		fromEmail = "#{@configurationParams.inviteUser.from.name} <#{@configurationParams.inviteUser.from.email}@#{@domain}>"
		subject = 'Welcome to Koality!'
		uri = 'https://' + @domain + '/create/account?token=' + userToken
		body = "Click here to create your account: #{uri}"

		@emailer.sendText fromEmail, toEmail, subject, body, (error) ->
			console.error error if error?
			callback error if callback?
