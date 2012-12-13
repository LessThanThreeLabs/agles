window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () =>
		@accountHeaderMenuOptionModel = new AccountHeaderMenuOption.Model()
		@loginHeaderMenuOptionModel = new LoginHeaderMenuOption.Model()
		@repositoryHeaderMenuOptionModel = new RepositoryHeaderMenuOption.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	html: ''


	initialize: () =>
		@accountHeaderMenuOptionView = new AccountHeaderMenuOption.View model: @model.accountHeaderMenuOptionModel
		@loginHeaderMenuOptionView = new LoginHeaderMenuOption.View model: @model.loginHeaderMenuOptionModel
		@repositoryHeaderMenuOptionView = new RepositoryHeaderMenuOption.View model: @model.repositoryHeaderMenuOptionModel


	onDispose: () =>
		@accountHeaderMenuOptionView.dispose()
		@loginHeaderMenuOptionView.dispose()
		@repositoryHeaderMenuOptionView.dispose()
		

	render: () =>
		@$el.html @html

		@$el.append @accountHeaderMenuOptionView.render().el
		@$el.append @loginHeaderMenuOptionView.render().el
		@$el.append @repositoryHeaderMenuOptionView.render().el
		
		return @
