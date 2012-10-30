window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () ->
		@accountHeaderOptionModel = new AccountHeaderOption.Model()
		@loginHeaderOptionModel = new LoginHeaderOption.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	template: Handlebars.compile ''

	initialize: () ->
		@accountHeaderOptionView = new AccountHeaderOption.View model: @model.accountHeaderOptionModel
		@loginHeaderOptionView = new LoginHeaderOption.View model: @model.loginHeaderOptionModel


	render: () ->
		@$el.html @template()
		@$el.append @accountHeaderOptionView.render().el
		@$el.append @loginHeaderOptionView.render().el
		return @
