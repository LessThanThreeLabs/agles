window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	defaults:
		name: null
		description: null
		url: null


	initialize: () =>
		@repositoryHeaderBasicInformationModel = new RepositoryHeaderBasicInformation.Model()
		@repositoryHeaderMenuModel = new RepositoryHeaderMenu.Model()

		@on 'change:name change:description', () =>
			attributesToSet = 
				name: @get 'name'
				description: @get 'description'
			@repositoryHeaderBasicInformationModel.set attributesToSet,
				error: (model, error) => console.error error
		@on 'change:url', () =>
			attributesToSet = url: @get 'url'
			@repositoryHeaderMenuModel.repositoryUrlTrinketModel.set attributesToSet,
				error: (model, error) => console.error error


	fetchRepositoryInformation: () =>
		@clear()

		requestData = id: globalRouterModel.get 'repositoryId'
		socket.emit 'repos:read', requestData, (error, data) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@set data,
					error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.name isnt 'string' or attributes.name.length is 0
			return new Error 'Invalid repository name: ' + attributes.name

		if typeof attributes.description isnt 'string' or attributes.description.length is 0
			return new Error 'Invalid repository description: ' + attributes.description

		if typeof attributes.url isnt 'string' or attributes.url.length is 0
			return new Error 'Invalid repository url: ' + attributes.url

		return


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	html: '<div class="repositoryHeaderBasicInformationContainer"></div>
		<div class="repositoryHeaderMenuContainer"></div>'


	initialize: () =>
		@repositoryHeaderBasicInformationView = new RepositoryHeaderBasicInformation.View model: @model.repositoryHeaderBasicInformationModel
		@repositoryHeaderMenuView = new RepositoryHeaderMenu.View model: @model.repositoryHeaderMenuModel

		@model.fetchRepositoryInformation()


	onDispose: () =>
		@repositoryHeaderBasicInformationView.dispose()
		@repositoryHeaderMenuView.dispose()


	render: () =>
		@$el.html @html
		@$('.repositoryHeaderBasicInformationContainer').html @repositoryHeaderBasicInformationView.render().el
		@$('.repositoryHeaderMenuContainer').html @repositoryHeaderMenuView.render().el
		return @
