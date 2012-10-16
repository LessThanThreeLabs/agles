assert = require 'assert'
nodemailer = require 'nodemailer'

Resource = require '../resource'
CreateAccountEmailer = require './createAccountEmailer'


exports.create = (configurationParams, modelRpcConnection) ->
	createAccountEmailer = CreateAccountEmailer.create configurationParams.createAccount.email
	return new UsersResource configurationParams, modelRpcConnection, createAccountEmailer


class UsersResource extends Resource
	constructor: (configurationParams, modelRpcConnection, @createAccountEmailer) ->
		assert.ok @createAccountEmailer?
		super configurationParams, modelRpcConnection


	create: (socket, data, callback) ->
		if data.email? and data.password?
			if isAccountValid(data.email, data.password, data.firstName, data.lastName)
				@createAccountEmailer.sendEmailToUser data.firstName, data.lastName, data.email
				callback null, true
			else
				callback 'Invalid account data'
		else
			callback 'Parsing error'


	update: (socket, data, callback) ->
		if data.email? and data.password? and data.rememberMe?
			console.log 'need to check that the username and password are correct from the model server'
			callback null, true
		else
			callback 'Parsing error'



isAccountValid = (email, password, firstName, lastName) ->
	emailRegex = new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
	return email.toLowerCase().match(emailRegex) and password.length >= 8 and firstName isnt '' and lastName isnt ''
