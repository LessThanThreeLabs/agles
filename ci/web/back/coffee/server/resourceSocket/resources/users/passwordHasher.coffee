assert = require 'assert'
crypto = require 'crypto'


exports.create = () ->
	return new PasswordHasher()


class PasswordHasher
	getPasswordHash: (password, callback) =>
		crypto.randomBytes 16, (error, salt) =>
			if error
				callback error
			else
				callback null,
					salt: salt.toString 'base64'
					passwordHash: @hashPasswordWithSalt password, salt


	hashPasswordWithSalt: (password, salt) =>
		return crypto.createHash('sha512').update(salt, 'ascii').update(password, 'utf8').digest('base64')
