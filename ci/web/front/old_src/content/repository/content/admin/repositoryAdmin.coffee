window.RepositoryAdmin = {}


class RepositoryAdmin.Model extends Backbone.Model

	initialize: () =>
		menuOptions = [new PrettyMenuOption('general', 'General'), 
			new PrettyMenuOption('members', 'Members'),
			new PrettyMenuOption('github', 'Github')]

		@prettyMenuModel = new PrettyMenu.Model
			options: menuOptions
			selectedOptionName: menuOptions[0].name

		@repositoryAdminContentModel = new RepositoryAdminContent.Model()

		@prettyMenuModel.on 'change:selectedOptionName', ()  =>
			@repositoryAdminContentModel.set 'view', @prettyMenuModel.get 'selectedOptionName'
			# globalRouterModel.set 'adminView', @prettyMenuModel.get('selectedOptionName'),
			# 	error: (model, error) => console.error error
		@repositoryAdminContentModel.set 'view', @prettyMenuModel.get 'selectedOptionName'


class RepositoryAdmin.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdmin'
	html: '<div class="repositoryAdminMenuContainer"></div>
			<div class="repositoryAdminContentContainer"></div>'


	initialize: () =>
		@prettyMenuView = new PrettyMenu.View model: @model.prettyMenuModel
		@repositoryAdminContentView = new RepositoryAdminContent.View model: @model.repositoryAdminContentModel


	onDispose: () =>
		@prettyMenuView.dispose()
		@repositoryAdminContentView.dispose()


	render: () =>
		@$el.html @html
		@$('.repositoryAdminMenuContainer').html @prettyMenuView.render().el
		@$('.repositoryAdminContentContainer').html @repositoryAdminContentView.render().el
		return @
