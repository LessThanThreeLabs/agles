window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	default:
		repositoryId: null
		name: ''
		description: ''
		url: ''

	initialize: () =>
		@repositoryUrlPanelModel = new RepositoryUrlPanel.Model()

		@on 'change:repositoryId', () =>
			@_getRepositoryInformation()
		@on 'change:url', () =>
			@repositoryUrlPanelModel.set 'url', @get 'url'


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
	template: Handlebars.compile '<div class="repositoryNameAndDescription">
			<div class="repositoryName">> {{name}}</div>
			<div class="repositoryDescription">{{description}}</div>
		</div>
		<div class="repositoryUrlContainer"></div>'

	initialize: () =>
		@repositoryUrlPanelView = new RepositoryUrlPanel.View model: @model.repositoryUrlPanelModel

		@model.on 'change:name', @render
		@model.on 'change:description', @render


	render: () =>
		@$el.html @template
			name: @model.get 'name'
			description: @model.get 'description'
		@$el.find('.repositoryUrlContainer').html @repositoryUrlPanelView.render().el
		return @
