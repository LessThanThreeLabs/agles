window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () =>
		@accountHeaderMenuOptionModel = new AccountHeaderMenuOption.Model()
		# @loginHeaderOptionModel = new LoginHeaderOption.Model()
		@repositoryHeaderMenuOptionModel = new RepositoryHeaderMenuOption.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	html: ''


	initialize: () =>
		@accountHeaderMenuOptionView = new AccountHeaderMenuOption.View model: @model.accountHeaderMenuOptionModel
		# @loginHeaderOptionView = new LoginHeaderOption.View model: @model.loginHeaderOptionModel
		@repositoryHeaderMenuOptionView = new RepositoryHeaderMenuOption.View model: @model.repositoryHeaderMenuOptionModel


	onDispose: () =>
		@accountHeaderMenuOptionView.dispose()
		# @loginHeaderOptionView.dispose()
		@repositoryHeaderMenuOptionView.dispose()
		

	render: () =>
		@$el.html @html

		@$el.append @accountHeaderMenuOptionView.render().el
		# @$el.append @loginHeaderOptionView.render().el
		@$el.append @repositoryHeaderMenuOptionView.render().el
		
		return @
