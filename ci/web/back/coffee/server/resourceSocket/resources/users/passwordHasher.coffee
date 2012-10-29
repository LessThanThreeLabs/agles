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
				console.log 'password: ' + password

				callback null,
					salt: salt
					passwordHash: crypto.createHash('sha512').update(salt).update(password, 'utf8').digest()


	hashPasswordWithSalt: (password, salt) =>
		return crypto.createHash('sha512').update(salt).update(password, 'utf8').digest()
