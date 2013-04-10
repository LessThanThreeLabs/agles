assert = require 'assert'
Mailgun = require('mailgun').Mailgun

FeedbackEmailer = require './mailTypes/feedbackEmailer'
InviteUserEmailer = require './mailTypes/inviteUserEmailer'
ResetPasswordEmailer = require './mailTypes/resetPasswordEmailer'
InitialAdminEmailer = require './mailTypes/initialAdminEmailer'
LoggerEmailer = require './mailTypes/loggerEmailer'


exports.create = (configurationParams, domainRetriever) ->
	createEmailers = () ->
		feedback: FeedbackEmailer.create configurationParams.feedback, emailSender, domainRetriever
		inviteUser: InviteUserEmailer.create configurationParams.inviteUser, emailSender, domainRetriever
		resetPassword: ResetPasswordEmailer.create configurationParams.resetPassword, emailSender, domainRetriever
		initialAdmin: InitialAdminEmailer.create configurationParams.initialAdmin, emailSender, domainRetriever
		logger: LoggerEmailer.create configurationParams.logger, emailSender, domainRetriever
		
	emailSender = new Mailgun configurationParams.mailgun.key
	return createEmailers()
