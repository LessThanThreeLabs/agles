window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () ->
		@repositoryHeaderOptionModel = new RepositoryHeaderOption.Model()
		@accountHeaderOptionModel = new AccountHeaderOption.Model()
		@loginHeaderOptionModel = new LoginHeaderOption.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	template: Handlebars.compile ''

	initialize: () ->
		@repositoryHeaderOptionView = new RepositoryHeaderOption.View model: @model.repositoryHeaderOptionModel
		@accountHeaderOptionView = new AccountHeaderOption.View model: @model.accountHeaderOptionModel
		@loginHeaderOptionView = new LoginHeaderOption.View model: @model.loginHeaderOptionModel


	render: () ->
		@$el.html @template()
		@$el.append @repositoryHeaderOptionView.render().el
		@$el.append @accountHeaderOptionView.render().el
		@$el.append @loginHeaderOptionView.render().el
		return @
