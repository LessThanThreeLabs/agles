assert = require 'assert'
Mailgun = require('mailgun').Mailgun

FeedbackEmailer = require './mailTypes/feedbackEmailer'
InviteUserEmailer = require './mailTypes/inviteUserEmailer'
ResetPasswordEmailer = require './mailTypes/resetPasswordEmailer'


exports.create = (configurationParams, domain) ->
	emailer = new Mailgun configurationParams.mailgun.key

	toReturn =
		feedback: FeedbackEmailer.create configurationParams, domain, emailer
		inviteUser: InviteUserEmailer.create configurationParams, domain, emailer
		resetPassword: ResetPasswordEmailer.create configurationParams, domain, emailer
	toReturn
