assert = require 'assert'
crypto = require 'crypto'


exports.create = () ->
	return new PasswordHasher()


class PasswordHasher
	getPasswordHash: (password, callback) =>
		assert.ok password?
		assert.ok callback?

		crypto.randomBytes 16, (error, salt) =>
			if error
				callback error
			else
				salt = salt.toString 'base64'
				callback null,
					salt: salt
					passwordHash: @hashPasswordWithSalt password, salt


	hashPasswordWithSalt: (password, salt) =>
		assert.ok password?
		assert.ok salt?
		
		return crypto.createHash('sha512').update(salt, 'ascii').update(password, 'utf8').digest('base64')
