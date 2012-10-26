assert = require 'assert'


exports.create = () ->
	return new AccountInformationValidator()


class AccountInformationValidator

	isEmailValid: (email) =>
		emailRegex = new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
		
		if not email.toLowerCase().match emailRegex
			return 'Invaild email address'
		else
			return 'ok'


	isPasswordValid: (password) =>
		passwordRegex = new RegExp "^(?=.*[a-zA-Z])(?=.*\\d).+$"

		if not password? or password.length < 8 or password.match passwordRegex
			return 'Password must be at least 8 characters, contain a letter, and contain a number'
		else
			return 'ok'


	isFirstNameValid: (firstName) =>
		firstNameRegex = new RegExp "^[A-Z][-'a-zA-Z]+$"

		if not firstName? or firstName.match firstNameRegex
			return 'Check name formatting'
		else
			return 'ok'


	isLastNameValid: (lastName) =>
		lastNameRegex = new RegExp "^[A-Z][-'a-zA-Z]+$"

		if not lastName? or lastName.match lastNameRegex
			return 'Check name formatting'
		else
			return 'ok'
