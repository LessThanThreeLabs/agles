assert = require 'assert'
fs = require 'fs'
crypto = require 'crypto'
spawn = require('child_process').spawn
exec = require('child_process').exec


exports.create = () ->
	return new SshKeyGenerator


class SshKeyGenerator
	
	generateKey: (callback) =>
		crypto.randomBytes 8, (error, randomBuffer) =>
			if error? then callback error
			else
				filename = '/tmp/node-ssh-key-' + randomBuffer.toString 'hex'
				console.log filename

				exec "ssh-keygen -trsa -N '' -f #{filename}", (error, stdout, stderr) =>
					if error? then callback error
					else @_getFileContentsAndDeleteFiles filename, callback


	_getFileContentsAndDeleteFiles: (filename, callback) =>
		privateKeyFilename = filename
		publicKeyFilename = filename + '.pub'

		await
			fs.readFile publicKeyFilename, defer publicKeyError, publicKeyContents
			fs.readFile privateKeyFilename, defer privateKeyError, privateKeyContents

		if publicKeyError?
			callback publicKeyError
		else if privateKeyError?
			callabck privateKeyError
		else
			fs.unlink publicKeyFilename
			fs.unlink privateKeyFilename

			callback null,
				public: publicKeyContents
				private: privateKeyContents
