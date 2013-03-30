assert = require 'assert'
Mailgun = require('mailgun').Mailgun

FeedbackEmailer = require './mailTypes/feedbackEmailer'
InviteUserEmailer = require './mailTypes/inviteUserEmailer'
ResetPasswordEmailer = require './mailTypes/resetPasswordEmailer'


exports.create = (configurationParams, modelRpcConnection) ->
	emailer = new Mailgun configurationParams.mailgun.key

	toReturn =
		feedback: FeedbackEmailer.create configurationParams, modelRpcConnection, emailer
		inviteUser: InviteUserEmailer.create configurationParams, modelRpcConnection, emailer
		resetPassword: ResetPasswordEmailer.create configurationParams, modelRpcConnection, emailer
	toReturn
