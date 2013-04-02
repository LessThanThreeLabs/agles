assert = require 'assert'
crypto = require 'crypto'

Handler = require '../../handler'


exports.create = (stores, modelRpcConnection, passwordHasher, accountInformationValidator, mailer, initialAdminToken) ->
	return new UsersCreateHandler stores, modelRpcConnection, passwordHasher, accountInformationValidator, mailer, initialAdminToken


class UsersCreateHandler extends Handler
	constructor: (@stores, modelRpcConnection, @passwordHasher, @accountInformationValidator, @mailer, @initialAdminToken) ->
		super modelRpcConnection
		assert.ok @stores?
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?
		assert.ok @mailer?
		assert.ok @initialAdminToken?


	createUser: (socket, data, callback) =>
		if not data?.email? or not data?.password? or not data?.firstName? or not data?.lastName? or not data?.token?
			callback 400
		else
			errors = @_getUserInformationErrors data.email, data.firstName, data.lastName, data.password
			if errors?
				callback errors
				return

			# This checks against the following attack:
			#   Client attempts to create an account for his own email address,
			#   using someone else's token.
			@stores.createAccountStore.getAccount data.token, (error, account) =>
				if error? then callback 500
				else if account.email isnt data.email then callback 403
				else
					data.isAdmin = false
					@_addUser socket.session, data, callback


	_getUserInformationErrors: (email, firstName, lastName, password) =>
		errors = {}
		if not @accountInformationValidator.isValidEmail email
			errors.email = @accountInformationValidator.getInvalidEmailString()
		if not @accountInformationValidator.isValidFirstName firstName
			errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
		if not @accountInformationValidator.isValidLastName lastName 
			errors.lastName = @accountInformationValidator.getInvalidLastNameString()
		if not @accountInformationValidator.isValidPassword password
			errors.password = @accountInformationValidator.getInvalidPasswordString()

		if Object.keys(errors).length isnt 0 then return errors
		else return null


	_addUser: (session, account, callback) =>
		@passwordHasher.getPasswordHash account.password, (passwordHashError, passwordHashResult) =>
			if passwordHashError?
				callback 500
			else
				@modelRpcConnection.users.create.create_user account.email, account.firstName, account.lastName, 
					passwordHashResult.passwordHash, passwordHashResult.salt, account.isAdmin, (error, userId) =>
						if error?.type is 'UserAlreadyExistsError' then callback 'user already exists'
						else if error? then callback 500
						else
							session.userId = userId
							session.save()

							callback()


	getEmailFromToken: (socket, data, callback) =>
		if not data?.token?
			callback 400
		else
			@stores.createAccountStore.getAccount data.token, (error, account) =>
				if error? then callback 500
				else callback null, account.email


	inviteUsers: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.emails?
			callback 400
		else
			if data.emails.indexOf(',') isnt -1
				emails = data.emails.split ','
			else if data.emails.indexOf(';') isnt -1
				emails = data.emails.split ';'
			else
				emails = data.emails.split '\n'

			emails = emails.map (email) -> return email.trim()

			for email in emails
				if not @accountInformationValidator.isValidEmail email
					callback 'bad email'
					return

			@_getUnusedEmails emails, (error, unusedEmails) =>
				if error?
					callback 500
				else
					@_sendEmailInvites unusedEmails, (error) =>
						if error? then callback 500
						else callback()


	_getUnusedEmails: (emails, callback) =>
		emailInUseErrors = []
		emailInUse = []

		await
			for email, index in emails
				@modelRpcConnection.users.read.email_in_use email, defer emailInUseErrors[index], emailInUse[index]

		emailInUseErrors = emailInUseErrors.filter (error) -> error?

		if emailInUseErrors.length isnt 0
			callback 500
		else
			emailsNotInUse = []
			for email, index in emails
				emailsNotInUse.push email if not emailInUse[index]

			callback null, emailsNotInUse


	_sendEmailInvites: (emails, callback) =>
		emailErrors = []
		await
			for email, index in emails
				@_sendEmailAndAddToStore email, defer emailErrors[index]

		emailErrors = emailErrors.filter (error) -> return error?

		if emailErrors.length isnt 0
			callback 400
		else
			callback()


	_sendEmailAndAddToStore: (email, callback) =>
		crypto.randomBytes 4, (keyError, keyBuffer) =>
			if keyError?
				callback keyError
			else
				key = keyBuffer.toString 'hex'
				@stores.createAccountStore.addAccount key, email: email
				@mailer.inviteUser.email email, key, callback


	validateInitialAdminUser: (socket, data, callback) =>
		if not data?.email? or not data?.password? or not data?.firstName? or not data?.lastName?
			callback 400
		else
			errors = @_getUserInformationErrors data.email, data.firstName, data.lastName, data.password
			if errors?
				callback errors
				return

			@mailer.initialAdmin.email data.email, data.firstName, data.lastName, @initialAdminToken, (error) =>
				if error? then callback 500
				else callback()


	validateInitialAdminToken: (socket, data, callback) =>
		if not data?.token?
			callback 400
		else
			if data.token isnt @initialAdminToken then callback 'bad token'
			else callback()
			

	createInitialAdmin: (socket, data, callback) =>
		if not data?.email? or not data?.password? or not data?.firstName? or not data?.lastName? or not data?.token?
			callback 400
		else
			if data.token isnt @initialAdminToken
				callback 'bad token'
				return

			console.log 'need to check that database has not been initialized!!!!'
			
			data.isAdmin = true
			@_addUser socket.session, data, callback

			callback()
