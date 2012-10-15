window.CreateAccount = {}


class CreateAccount.Model extends Backbone.Model

	initialize: () ->
		@createAccountPanelModel = new CreateAccountPanel.Model()


class CreateAccount.View extends Backbone.View
	tagName: 'div'
	className: 'createAccount headerMenuOption'
	template: Handlebars.compile 'Create Account'
	events: 'click': '_clickHandler'


	initialize: () =>
		@createAccountPanelView = new CreateAccountPanel.View model: @model.createAccountPanelModel


	render: () =>
		@$el.html @template()
		@_addCreateAccountPanelView()
		return @


	_addCreateAccountPanelView: () =>
		$('body').append @createAccountPanelView.render().el


	_clickHandler: () =>
		@model.createAccountPanelModel.toggleVisibility()
