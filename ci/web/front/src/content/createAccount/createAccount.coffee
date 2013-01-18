window.CreateAccount = {}


class CreateAccount.Model extends Backbone.Model

	initialize: () =>
		@createAccountFormModel = new CreateAccountForm.Model()
		@createAccountSuccessModel = new CreateAccountSuccess.Model()

		@createAccountFormModel.on 'change:email change:firstName change:lastName', () =>
			attributesToSet =
				email: @createAccountFormModel.get 'email'
				firstName: @createAccountFormModel.get 'firstName'
				lastName: @createAccountFormModel.get 'lastName'
			@createAccountSuccessModel.set attributesToSet,
				error: (model, error) => console.error error


class CreateAccount.View extends Backbone.View
	tagName: 'div'
	className: 'createAccount'
	html: ''


	initialize: () =>
		@createAccountFormView = new CreateAccountForm.View model: @model.createAccountFormModel
		@createAccountSuccessView = new CreateAccountSuccess.View model: @model.createAccountSuccessModel

		@createAccountFormView.on 'accountCreated', @_showSuccess, @


	onDispose: () =>
		@createAccountFormView.off null, null, @

		@createAccountFormView.dispose()
		@createAccountSuccessView.dispose()


	render: () =>
		@$el.html @createAccountFormView.render().el
		return @


	_showSuccess: () =>
		@$el.html @createAccountSuccessView.render().el
