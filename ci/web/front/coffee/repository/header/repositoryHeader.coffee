window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	defaults:
		name: null
		description: null
		url: null


	initialize: () =>
		@repositoryHeaderBasicInformationModel = new RepositoryHeaderBasicInformation.Model()
		@repositoryHeaderMenuModel = new RepositoryHeaderMenu.Model()

		@on 'change:name', () =>
			@repositoryHeaderBasicInformationModel.set 'name', @get 'name'
		@on 'change:description', () =>
			@repositoryHeaderBasicInformationModel.set 'description', @get 'description'
		@on 'change:url', () =>
			@repositoryHeaderMenuModel.set 'url', @get 'url'


	fetchRepositoryInformation: () =>
		@clear()

		return if not globalRouterModel.get('repositoryId')?

		requestData = id: globalRouterModel.get 'repositoryId'
		socket.emit 'repos:read', requestData, (error, data) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@set data


	validate: (attributes) =>
		if attributes.name? and attributes.name.length is 0
			return new Error 'Invalid repository name'

		if attributes.description? and attributes.description.length is 0
			return new Error 'Invalid repository description'

		if attributes.url? and attributes.url.length is 0
			return new Error 'Invalid repository url'

		return


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	html: '<div class="repositoryHeaderContainer">
			<div class="repositoryNameAndDescription"></div>
			<div class="repositoryUrlAndMenu"></div>
		</div>'


	initialize: () =>
		@repositoryHeaderBasicInformationView = new RepositoryHeaderBasicInformation.View model: @model.repositoryHeaderBasicInformationModel
		@repositoryHeaderMenuView = new RepositoryHeaderMenu.View model: @model.repositoryHeaderMenuModel

		globalRouterModel.on 'change:repositoryId', @model.fetchRepositoryInformation, @
		
		@model.fetchRepositoryInformation()


	onDispose: () =>
		globalRouterModel.off null, null, @
		@repositoryHeaderBasicInformationView.dispose()
		@repositoryHeaderMenuView.dispose()


	render: () =>
		@$el.html @html
		@$el.find('.repositoryNameAndDescription').append @repositoryHeaderBasicInformationView.render().el
		@$el.find('.repositoryUrlAndMenu').append @repositoryHeaderMenuView.render().el
		return @
