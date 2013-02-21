assert = require 'assert'
fs = require 'fs'
crypto = require 'crypto'
exec = require('child_process').exec


exports.create = (configurationParams) ->
	return new SshKeyPairGenerator configurationParams


class SshKeyPairGenerator
	constructor: (@configurationParams) ->
		assert.ok @configurationParams


	createKeyPair: (callback) =>
		crypto.randomBytes 8, (error, randomBuffer) =>
			filename = '/tmp/node-ssh-keygen-' + randomBuffer.toString 'hex'

			exec "ssh-keygen -N '' -f #{filename}", (error, stdout, stderr) =>
				if error? then callback error
				else @_getKeysAndDeleteFiles filename, callback


	_getKeysAndDeleteFiles: (filename, callback) =>
		privateKeyFileName = filename
		publicKeyFilename = filename + '.pub'

		await
			fs.readFile privateKeyFileName, 'ascii', defer privateKeyError, privateKeyContents
			fs.readFile publicKeyFilename, 'ascii', defer publicKeyError, publicKeyContents

		if privateKeyError?
			callback privateKeyError
		else if publicKeyError?
			callback publicKeyError
		else
			fs.unlink privateKeyFileName
			fs.unlink publicKeyFilename

			callback null,
				private: privateKeyContents
				public: publicKeyContents
