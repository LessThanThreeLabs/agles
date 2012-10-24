window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () ->
		@createAccountModel = new CreateAccount.Model()
		@loginModel = new Login.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	template: Handlebars.compile ''

	initialize: () ->
		@createAccountView = new CreateAccount.View model: @model.createAccountModel
		@loginView = new Login.View model: @model.loginModel


	render: () ->
		@$el.html @template()
		@$el.append @createAccountView.render().el
		@$el.append @loginView.render().el
		return @
