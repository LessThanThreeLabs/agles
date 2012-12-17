fs = require 'fs'
url = require 'url'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection) ->
	filesCacher = FilesCacher.create configurationParams, './cache/verifyAccount.json'
	return new VerifyAccountHandler configurationParams, stores, modelConnection, filesCacher


class VerifyAccountHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher) ->
		super configurationParams, stores, modelConnection, filesCacher


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

				@pushFiles request, response
				response.render 'index', @getTemplateValues request
