assert = require 'assert'
sys = require 'sys'
spawn = require('child_process').spawn
exec = require('child_process').exec


exports.create = () ->
	return new SshKeyGenerator


class SshKeyGenerator
	
	generateKey: (callback) =>
		fileName = '/tmp/node-ssh-key-' + Number(Math.random().toString().substr(2)).toString(36)
		console.log fileName

		ssh = exec "ssh-keygen -trsa -N '' -f #{fileName}", (error, stdout, stderr) ->
			console.error error if error?

			console.log stdout
			console.log stderr
