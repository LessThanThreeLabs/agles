assert = require 'assert'
Mailgun = require('mailgun').Mailgun

FeedbackEmailer = require './mailTypes/feedbackEmailer'
InviteUserEmailer = require './mailTypes/inviteUserEmailer'
ResetPasswordEmailer = require './mailTypes/resetPasswordEmailer'
InitialAdminEmailer = require './mailTypes/initialAdminEmailer'
LoggerEmailer = require './mailTypes/loggerEmailer'


exports.create = (configurationParams, modelRpcConnection) ->
	emailer = new Mailgun configurationParams.mailgun.key

	toReturn =
		feedback: FeedbackEmailer.create configurationParams, modelRpcConnection, emailer
		inviteUser: InviteUserEmailer.create configurationParams, modelRpcConnection, emailer
		resetPassword: ResetPasswordEmailer.create configurationParams, modelRpcConnection, emailer
		initialAdmin: InitialAdminEmailer.create configurationParams, modelRpcConnection, emailer
		logger: LoggerEmailer.create configurationParams, modelRpcConnection, emailer
	toReturn
