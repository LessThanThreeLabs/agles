window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	defaults:
		repositoryId: null
		name: null
		description: null
		url: null
		mode: null

	initialize: () =>
		@repositoryHeaderBasicInformationModel = new RepositoryHeaderBasicInformation.Model()
		@repositoryHeaderMenuModel = new RepositoryHeaderMenu.Model()

		@repositoryHeaderMenuModel.on 'change:selectedMenuOptionName', () =>
			@set 'mode', @repositoryHeaderMenuModel.get 'selectedMenuOptionName'

		@on 'change:repositoryId', () =>
			@repositoryHeaderMenuModel.set 'repositoryId', @get 'repositoryId'
			@_getRepositoryInformation()
		@on 'change:name', () =>
			@repositoryHeaderBasicInformationModel.set 'name', @get 'name'
		@on 'change:description', () =>
			@repositoryHeaderBasicInformationModel.set 'description', @get 'description'
		@on 'change:url', () =>
			@repositoryHeaderMenuModel.set 'url', @get 'url'
		@on 'change:mode', () =>
			@repositoryHeaderMenuModel.set 'selectedMenuOptionName', @get 'mode'


	validate: (attributes) =>
		if attributes.name? and attributes.name.length is 0
			console.log '1 ' + attributes.name
			return new Error 'Invalid repository name'

		if attributes.description? and attributes.description.length is 0
			console.log '2'
			return new Error 'Invalid repository description'

		if attributes.url? and attributes.url.length is 0
			console.log '3'
			return new Error 'Invalid repository url'

		return


	_getRepositoryInformation: () =>
		requestData = id: @get 'repositoryId'
		socket.emit 'repos:read', requestData, (error, data) =>
			console.error error if error?
			@set data if data?


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	template: Handlebars.compile '<div class="repositoryHeaderContainer">
			<div class="repositoryNameAndDescription"></div>
			<div class="repositoryUrlAndMenu">
				<!--<div class="repositoryUrlAndMenuContainer">
				</div>-->
			</div>
		</div>'

	initialize: () =>
		@repositoryHeaderBasicInformationView = new RepositoryHeaderBasicInformation.View model: @model.repositoryHeaderBasicInformationModel
		@repositoryHeaderMenuView = new RepositoryHeaderMenu.View model: @model.repositoryHeaderMenuModel


	render: () =>
		@$el.html @template()
		@$el.find('.repositoryNameAndDescription').append @repositoryHeaderBasicInformationView.render().el
		@$el.find('.repositoryUrlAndMenu').append @repositoryHeaderMenuView.render().el
		return @
