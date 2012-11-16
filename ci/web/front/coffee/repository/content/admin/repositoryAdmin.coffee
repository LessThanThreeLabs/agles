window.RepositoryAdmin = {}


class RepositoryAdmin.Model extends Backbone.Model
	defaults:
		repositoryId: null

	initialize: () ->
		@repositoryAdminMenuModel = new RepositoryAdminMenu.Model
			options: ['General', 'Members']
			selectedOption: 'General'
		@repositoryAdminContentModel = new RepositoryAdminContent.Model()

		@on 'change:repositoryId', () =>
			@repositoryAdminContentModel.set 'repositoryId', @get 'repositoryId'

		@repositoryAdminMenuModel.on 'change:selectedOption', ()  =>
			console.log 'need to handle menu change'


class RepositoryAdmin.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdmin'

	initialize: () ->

	render: () ->
		repositoryAdminMenuView = new RepositoryAdminMenu.View model: @model.repositoryAdminMenuModel
		@$el.html repositoryAdminMenuView.render().el

		repositoryAdminContentView = new RepositoryAdminContent.View model: @model.repositoryAdminContent
		@$el.append repositoryAdminContentView.render().el

		return @
