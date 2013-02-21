assert = require 'assert'
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
				fileName = '/tmp/node-ssh-key-' + randomBuffer.toString 'hex'
				console.log fileName

				exec "ssh-keygen -trsa -N '' -f #{fileName}", (error, stdout, stderr) =>
					if error? then callback error
					else
						console.log stdout
						console.log stderr
