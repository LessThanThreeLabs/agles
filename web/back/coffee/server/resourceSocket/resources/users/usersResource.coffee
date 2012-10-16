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
			console.log 'need to do stuff with email and password...'
			sendEmailToUser 'jordannpotter@gmail.com'
			callback null, true
		else
			callback 'Parsing error'


	update: (socket, data, callback) ->
		if data.email? and data.password? and data.rememberMe?
			console.log 'need to check that the username and password are correct from the model server'
			callback null, true
		else
			callback 'Parsing error'


sendEmailToUser = (email) ->
	# WANT TO BE REUSING THIS!!!!....
	# or maybe that's what this line does in the library?....
	mailTransport = nodemailer.createTransport 'SMTP',
		service: 'Gmail'
		auth:
			user: 'create-account@lessthanthreelabs.com'
			pass: 'tentacles69!'

	mailOptions = 
		from: 'Create Account <create-account@lessthanthreelabs.com>'
		to: email
		subject: 'sup nerd'
		text: 'nerd up!'
		html: '<b>nerd up!</b>'

	mailTransport.sendMail mailOptions, (error, response) ->
		console.log 'error: ' + error if error?
		console.log 'response: ' + response if response?
		console.log 'done!'
