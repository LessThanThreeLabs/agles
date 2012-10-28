assert = require 'assert'


exports.create = () ->
	return new AccountInformationValidator()


class AccountInformationValidator
	emailRegex: new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
	passwordRegex: new RegExp "^(?=.*[a-zA-Z])(?=.*\\d).+$"
	firstNameRegex: new RegExp "^[A-Z][-'a-zA-Z]+$"
	lastNameRegex: new RegExp "^[A-Z][-'a-zA-Z]+$"


	isEmailValid: (email) =>
		if not email? or not email.toLowerCase().match @emailRegex
			return 'Invaild email address'
		else
			return 'ok'


	isPasswordValid: (password) =>
		if not password? or password.length < 8 or not password.match @passwordRegex
			return 'Password must be at least 8 characters, contain a letter, and contain a number'
		else
			return 'ok'


	isFirstNameValid: (firstName) =>
		if not firstName? or not firstName.match @firstNameRegex
			return 'Check name formatting'
		else
			return 'ok'


	isLastNameValid: (lastName) =>
		if not lastName? or not lastName.match @lastNameRegex
			return 'Check name formatting'
		else
			return 'ok'
