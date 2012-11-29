window.RepositoryAdmin = {}


class RepositoryAdmin.Model extends Backbone.Model
	defaults:
		repositoryId: null


	initialize: () =>
		menuOptions = [new RepositoryAdminMenuOption('general', 'General'), 
			new RepositoryAdminMenuOption('members', 'Members')]

		@repositoryAdminMenuModel = new RepositoryAdminMenu.Model
			options: menuOptions
			selectedOptionName: menuOptions[0].name

		@repositoryAdminContentModel = new RepositoryAdminContent.Model()
		@repositoryAdminContentModel.set 'mode', @repositoryAdminMenuModel.get 'selectedOptionName'

		@on 'change:repositoryId', () =>
			@repositoryAdminContentModel.set 'repositoryId', @get 'repositoryId'

		@repositoryAdminMenuModel.on 'change:selectedOptionName', ()  =>
			@repositoryAdminContentModel.set 'mode', @repositoryAdminMenuModel.get 'selectedOptionName'


class RepositoryAdmin.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdmin'
	html: ''


	initialize: () =>
		@repositoryAdminMenuView = new RepositoryAdminMenu.View model: @model.repositoryAdminMenuModel
		@repositoryAdminContentView = new RepositoryAdminContent.View model: @model.repositoryAdminContentModel

		window.globalRouterModel.on 'change:repositoryId', () =>
			@model.set 'repositoryId', window.globalRouterModel.get 'repositoryId'


	onDispose: () =>
		window.globalRouterModel.off null, null, @
		
		@repositoryAdminMenuView.dispose()
		@repositoryAdminContentView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @repositoryAdminMenuView.render().el
		@$el.append @repositoryAdminContentView.render().el
		return @
