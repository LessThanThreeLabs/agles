window.CreateAccountPanelValidator = class CreateAccountPanelValidator
	constructor: (@model) ->
		assert.ok @model?


	isEmailValid: () =>
		emailRegex = new RegExp "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\\b"
		return @model.get('email').toLowerCase().match emailRegex


	isPasswordValid: () =>
		return @model.get('password').length >= 8


	isVerifyPasswordValid: () =>
		return @model.get('password') is @model.get('verifyPassword')


	isFirstNameValid: () =>
		return @model.get('firstName') isnt ''


	isLastNameValid: () =>
		return @model.get('lastName') isnt ''


	allValid: () =>
		return @isEmailValid() and @isPasswordValid() and @isVerifyPasswordValid() and @isFirstNameValid() and @isLastNameValid()
