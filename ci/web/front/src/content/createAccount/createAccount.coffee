window.CreateAccount = {}


class CreateAccount.Model extends Backbone.Model

	initialize: () =>
		@createAccountFormModel = new CreateAccountForm.Model()


class CreateAccount.View extends Backbone.View
	tagName: 'div'
	className: 'createAccount'
	html: '<div class="createAccountFormContainer"></div>'


	initialize: () =>
		@createAccountFormView = new CreateAccountForm.View model: @model.createAccountFormModel


	onDispose: () =>
		@createAccountFormView.dispose()


	render: () =>
		@$el.html @html
		@$('.createAccountFormContainer').html @createAccountFormView.render().el
		return @
