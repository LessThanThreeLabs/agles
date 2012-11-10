window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	default:
		repositoryId: null
		name: ''
		description: ''
		url: ''
		mode: null

	initialize: () =>
		@repositoryHeaderBasicInformationModel = new RepositoryHeaderBasicInformation.Model()
		@repositoryUrlPanelModel = new RepositoryUrlPanel.Model()
		@repositoryHeaderMenuModel = new RepositoryHeaderMenu.Model()

		@on 'change:repositoryId', () =>
			@repositoryHeaderMenuModel.set 'repositoryId', @get 'repositoryId'
			@_getRepositoryInformation()
		@on 'change:name', () =>
			@repositoryHeaderBasicInformationModel.set 'name', @get 'name'
		@on 'change:description', () =>
			@repositoryHeaderBasicInformationModel.set 'description', @get 'description'
		@on 'change:url', () =>
			@repositoryUrlPanelModel.set 'url', @get 'url'
		@on 'change:mode', () =>
			@repositoryHeaderMenuModel.set 'selectedMenuOptionName', @get 'mode'


	validate: (attributes) =>
		if not attributes.repositoryId?
			return new Error 'Invalid repository id'

		if attributes.name? and attributes.name.length is 0
			return new Error 'Invalid repository name'

		if attributes.description? and attributes.description.length is 0
			return new Error 'Invalid repository description'

		if attributes.url? and attributes.url.length is 0
			return new Error 'Invalid repository url'

		return


	_getRepositoryInformation: () =>
		requestData = id: @get 'repositoryId'
		socket.emit 'repositories:read', requestData, (error, data) =>
			console.error error if error?
			@set data if data?


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	template: Handlebars.compile '<div class="repositoryNameAndDescription"></div>
		<div class="repositoryUrlAndMenu">
			<div class="repositoryUrlAndMenuContainer">
			</div>
		</div>'

	initialize: () =>
		@repositoryHeaderBasicInformationView = new RepositoryHeaderBasicInformation.View model: @model.repositoryHeaderBasicInformationModel
		@repositoryUrlPanelView = new RepositoryUrlPanel.View model: @model.repositoryUrlPanelModel
		@repositoryHeaderMenuView = new RepositoryHeaderMenu.View model: @model.repositoryHeaderMenuModel


	render: () =>
		@$el.html @template()
		@$el.find('.repositoryNameAndDescription').append @repositoryHeaderBasicInformationView.render().el
		@$el.find('.repositoryUrlAndMenuContainer').append @repositoryUrlPanelView.render().el
		@$el.find('.repositoryUrlAndMenuContainer').append '<div class="urlAndMenuSpacer"></div>'
		@$el.find('.repositoryUrlAndMenuContainer').append @repositoryHeaderMenuView.render().el
		return @
