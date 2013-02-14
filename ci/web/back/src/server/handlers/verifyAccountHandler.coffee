fs = require 'fs'
url = require 'url'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection, filesSuffix) ->
	filesCacher = FilesCacher.create 'verify account', configurationParams, './cache/verifyAccount.json', filesSuffix
	return new VerifyAccountHandler configurationParams, stores, modelConnection, filesCacher, filesSuffix


class VerifyAccountHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher, filesSuffix) ->
		super configurationParams, stores, modelConnection, filesCacher, filesSuffix


	handleRequest: (request, response) =>
		parsedUrl = url.parse request.url, true
		accountKey = parsedUrl.query.account

		if not accountKey?
			response.end 'Invalid link'
			return

		@stores.createAccountStore.getAccount accountKey, (error, account) =>
			if error?
				response.end 'Invalid link'
			else
				@stores.createAccountStore.removeAccount accountKey
				@_createUser request, response, account


	_createUser: (request, response, account) =>
		userToCreate =
			email: account.email
			salt: account.salt
			password_hash: account.passwordHash
			first_name: account.firstName
			last_name: account.lastName

		@modelConnection.rpcConnection.users.create.create_user userToCreate, (error, userId) =>
			if error?
				response.end 'User creation failed'
			else
				request.session.userId = userId
				request.session.email = account.email
				request.session.firstName = account.firstName
				request.session.lastName = account.lastName

				if account.rememberMe
					request.session.cookie.maxAge = @configurationParams.session.rememberMeDuration
					request.session.cookieExpirationIncreased ?= 0 
					request.session.cookieExpirationIncreased++

				@pushFiles request, response
				response.render 'index', @getTemplateValues request