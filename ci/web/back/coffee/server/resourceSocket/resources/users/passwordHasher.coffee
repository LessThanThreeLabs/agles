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
					salt: salt.toString('binary')
					passwordHash: @_saltPassword password, salt


	hashPasswordWithSalt: (password, salt) =>
		return @_saltPassword password, salt


	_saltPassword: (password, salt) =>
		crypto.createHash('sha512').update(salt, 'binary').update(password, 'utf8').digest('hex')
