window.LoginInformationValidator = class LoginInformationValidator

	isEmailValid: (email) =>
		emailRegex = new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
		return email.toLowerCase().match emailRegex


	isPasswordValid: (password) =>
		return password.length >= 8


	isFirstNameValid: (firstName) =>
		return firstName.length > 1


	isLastNameValid: (lastName) =>
		return lastName.length > 1
