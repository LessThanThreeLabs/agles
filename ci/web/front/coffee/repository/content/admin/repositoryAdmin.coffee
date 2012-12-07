window.RepositoryAdmin = {}


class RepositoryAdmin.Model extends Backbone.Model

	initialize: () =>
		menuOptions = [new SimpleMenuOption('general', 'General'), 
			new SimpleMenuOption('members', 'Members')]

		@simpleMenuModel = new SimpleMenu.Model
			options: menuOptions
			selectedOptionName: menuOptions[0].name

		@repositoryAdminContentModel = new RepositoryAdminContent.Model()

		@simpleMenuModel.on 'change:selectedOptionName', ()  =>
			@repositoryAdminContentModel.set 'mode', @simpleMenuModel.get 'selectedOptionName'
		@repositoryAdminContentModel.set 'mode', @simpleMenuModel.get 'selectedOptionName'


class RepositoryAdmin.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdmin'
	html: ''


	initialize: () =>
		@simpleMenuView = new SimpleMenu.View model: @model.simpleMenuModel
		@repositoryAdminContentView = new RepositoryAdminContent.View model: @model.repositoryAdminContentModel


	onDispose: () =>
		@simpleMenuView.dispose()
		@repositoryAdminContentView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @simpleMenuView.render().el
		@$el.append @repositoryAdminContentView.render().el
		return @
