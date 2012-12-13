window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () =>
		# @accountHeaderOptionModel = new AccountHeaderOption.Model()
		# @loginHeaderOptionModel = new LoginHeaderOption.Model()
		# @repositoryHeaderOptionModel = new RepositoryHeaderOption.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	html: ''


	initialize: () =>
		# @accountHeaderOptionView = new AccountHeaderOption.View model: @model.accountHeaderOptionModel
		# @loginHeaderOptionView = new LoginHeaderOption.View model: @model.loginHeaderOptionModel
		# @repositoryHeaderOptionView = new RepositoryHeaderOption.View model: @model.repositoryHeaderOptionModel


	onDispose: () =>
		# @accountHeaderOptionView.dispose()
		# @loginHeaderOptionView.dispose()
		# @repositoryHeaderOptionView.dispose()
		

	render: () =>
		@$el.html @html

		# @$el.append @accountHeaderOptionView.render().el
		# @$el.append @loginHeaderOptionView.render().el
		# @$el.append @repositoryHeaderOptionView.render().el
		
		return @
