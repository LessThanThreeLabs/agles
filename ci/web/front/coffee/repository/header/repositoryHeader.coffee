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

		window.globalRouterModel.on 'change:repositoryId', () =>
			@clear()
			@_getRepositoryInformation()


	_getRepositoryInformation: () =>
		requestData = id: window.globalRouterModel.get 'repositoryId'
		socket.emit 'repos:read', requestData, (error, data) =>
			console.error error if error?
			@set data if data?


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
	template: Handlebars.compile '<div class="repositoryHeaderContainer">
			<div class="repositoryNameAndDescription"></div>
			<div class="repositoryUrlAndMenu"></div>
		</div>'


	render: () =>
		@$el.html @template()

		repositoryHeaderBasicInformationView = new RepositoryHeaderBasicInformation.View model: @model.repositoryHeaderBasicInformationModel
		@$el.find('.repositoryNameAndDescription').append repositoryHeaderBasicInformationView.render().el
		
		repositoryHeaderMenuView = new RepositoryHeaderMenu.View model: @model.repositoryHeaderMenuModel
		@$el.find('.repositoryUrlAndMenu').append repositoryHeaderMenuView.render().el
		
		return @
