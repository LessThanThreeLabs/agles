assert = require 'assert'
crypto = require 'crypto'

Handler = require '../../handler'


exports.create = (stores, modelRpcConnection, passwordHasher, accountInformationValidator, inviteUserEmailer) ->
	return new UsersCreateHandler stores, modelRpcConnection, passwordHasher, accountInformationValidator, inviteUserEmailer


class UsersCreateHandler extends Handler
	constructor: (@stores, modelRpcConnection, @passwordHasher, @accountInformationValidator, @inviteUserEmailer) ->
		super modelRpcConnection
		assert.ok @stores?
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?
		assert.ok @inviteUserEmailer?


	createUser: (socket, data, callback) =>
		if not data?.email? or not data?.password? or not data?.firstName? or not data?.lastName?
			callback 400
		else
			errors = {}
			if not @accountInformationValidator.isValidFirstName data.firstName
				errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
			if not @accountInformationValidator.isValidLastName data.lastName 
				errors.lastName = @accountInformationValidator.getInvalidLastNameString()
			if not @accountInformationValidator.isValidPassword data.password
				errors.password = @accountInformationValidator.getInvalidPasswordString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

			@passwordHasher.getPasswordHash data.password, (passwordHashError, passwordHashResult) =>
				if passwordHashError?
					callback 500
				else
					@modelRpcConnection.users.create.create_user data.email, data.firstName, data.lastName, 
						passwordHashResult.passwordHash, passwordHashResult.salt, (error, userId) =>
							if error?.type is 'UserExistsError' then callback 'User already exists'
							else if error? then callback 500
							else
								socket.session.userId = userId
								socket.session.email = data.email
								socket.session.firstName = data.firstName
								socket.session.lastName = data.lastName
								socket.session.isAdmin = false
								socket.session.save()

								callback()


	inviteUsers: (socket, data, callback) =>
		console.log data

		userId = socket.session.userId
		if not userId? or not socket.session.isAdmin
			callback 403
		else if not data?.users?.emails?
			callback 400
		else
			if data.users.emails.indexOf(',') isnt -1
				emails = data.users.emails.split ','
			else if data.users.emails.indexOf(';') isnt -1
				emails = data.users.emails.split ';'
			else
				emails = data.users.emails.split '\n'

			emails = emails.map (email) -> return email.trim()

			for email in emails
				if not @accountInformationValidator.isValidEmail email
					callback 400
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
				@_sendEmailAndAddToStore email, emailErrors[index]

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
				@inviteUserEmailer.inviteUser email, key, callback
