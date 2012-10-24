assert = require 'assert'
crypto = require 'crypto'
nodemailer = require 'nodemailer'

Resource = require '../resource'
CreateAccountStore = require './createAccountStore'
CreateAccountEmailer = require './createAccountEmailer'


exports.create = (configurationParams, stores, modelRpcConnection) ->
	createAccountEmailer = CreateAccountEmailer.create configurationParams.createAccount.email, configurationParams.domain
	return new UsersResource configurationParams, stores, modelRpcConnection, createAccountEmailer


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelRpcConnection, @createAccountEmailer) ->
		assert.ok @createAccountEmailer?
		super configurationParams, stores, modelRpcConnection


	create: (socket, data, callback) ->
		if data.email? and data.password?
			if isAccountValid(data.email, data.password, data.firstName, data.lastName)
				@_createKeyAndAccount data, (error, keyAndAccount) =>
					{key, account} = keyAndAccount

					console.log key
					console.log account

					@stores.createAccountStore.addAccount key, account
					@createAccountEmailer.sendEmailToUser data.firstName, data.lastName, data.email, key
					
					callback null, true
			else
				callback 'Invalid account data'
		else
			callback 'Parsing error'



	_createKeyAndAccount: (data, callback) =>
		crypto.randomBytes 24, (error, buffer) =>
			callback error if error?

			key = buffer.toString('hex').substr 0, 16
			salt = buffer[8...24]

			callback null, 
				key: key
				account:
					email: data.email
					salt: salt
					passwordHash: crypto.createHash('sha512').update(salt).update(data.password, 'utf8').digest()
					firstName: data.firstName
					lastName: data.lastName


	update: (socket, data, callback) ->
		if data.email? and data.password? and data.rememberMe?
			console.log 'need to check that the username and password are correct from the model server'
			callback null, true
		else
			callback 'Parsing error'



isAccountValid = (email, password, firstName, lastName) ->
	emailRegex = new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
	return email.toLowerCase().match(emailRegex) and password.length >= 8 and firstName isnt '' and lastName isnt ''
