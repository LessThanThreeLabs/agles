assert = require 'assert'


exports.create = () ->
	return new AccountInformationValidator()


class AccountInformationValidator
	emailRegex: new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
	passwordRegex: new RegExp "^(?=.*[a-zA-Z])(?=.*\\d).+$"
	firstNameRegex: new RegExp "^[A-Z][-'a-zA-Z]+$"
	lastNameRegex: new RegExp "^[A-Z][-'a-zA-Z]+$"


	getInvalidEmailString: () =>
		return 'Invaild email address'


	isValidEmail: (email) =>
		return email? and email.toLowerCase().match @emailRegex


	getInvalidPasswordString: () =>
		return 'Password must be at least 8 characters, contain a letter, and contain a number'


	isValidPassword: (password) =>
		return password? and not password.length < 8 and password.match @passwordRegex


	getInvalidFirstNameString: () =>
		return 'Check name formatting'


	isValidFirstName: (firstName) =>
		return firstName? and firstName.match @firstNameRegex


	getInvalidLastNameString: () =>
		return 'Check name formatting'


	isValidLastName: (lastName) =>
		return lastName? and lastName.match @lastNameRegex


	getInvalidSshAliasString: () =>
		return "Invalid Alias"


	isValidSshAlias: (alias) =>
		return alias? and alias is not ''


	getInvalidSshKeyString: () =>
		return "Invalid Key"


	isValidSshKey: (key) =>
		return key? and key is not ''
