assert = require 'assert'


exports.create = () ->
	return new AccountInformationValidator()


class AccountInformationValidator
	emailRegex: new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
	passwordRegex: new RegExp "^(?=.*[a-zA-Z])(?=.*\\d).+$"
	firstNameRegex: new RegExp "^[A-Z][-'a-zA-Z]+$"
	lastNameRegex: new RegExp "^[A-Z][-'a-zA-Z]+$"


	isEmailValid: (email) =>
		if @validEmail email
			return 'ok'
		else
			return 'Invaild email address'


	validEmail: (email) =>
		email? and email.toLowerCase().match @emailRegex


	isPasswordValid: (password) =>
		if @validPassword password
			return 'ok'
		else
			return 'Password must be at least 8 characters, contain a letter, and contain a number'


	validPassword: (password) =>
		password? and not password.length < 8 and password.match @passwordRegex


	isFirstNameValid: (firstName) =>
		if @validFirstName firstName
			return 'ok'
		else
			return 'Check name formatting'


	validFirstName: (firstName) =>
		firstName? and firstName.match @firstNameRegex


	isLastNameValid: (lastName) =>
		if @validLastName lastName
			return 'ok'
		else
			return 'Check name formatting'


	validLastName: (lastName) =>
		lastName? and lastName.match @lastNameRegex


	validSshAlias: (alias) =>
		alias? and alias is not ''


	validSshKey: (key) =>
		key? and key is not ''
